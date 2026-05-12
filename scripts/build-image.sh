#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

IMAGE="uconsole-arch-cm5.img"
IMAGE_SIZE="8G"
MODEL="cm5"
ROOTFS_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
REPO_URL='https://repo.wdk.kr/uconsole-arch/$arch'
ALARM_MIRROR_URL=""
CACHE_DIR="$REPO_ROOT/.cache"
ROOTFS_TARBALL=""
ROOTFS_TARBALL_USER_SUPPLIED=0
VERIFY_ROOTFS=0
KEEP_MOUNTED=0
HOSTNAME="uconsole"
MINIMIZE=0
SHRINK_FREE_SPACE="768M"
COMPRESS="none"
COMPRESSION_LEVEL="19"
COMPRESSED_IMAGE=""

EXTRA_PACKAGES=()
BASE_PACKAGES=(networkmanager openssh sudo vim nano)

LOOPDEV=""
MOUNT_ROOT=""
CURRENT_STEP="initializing"

usage() {
  cat <<'USAGE'
Usage: sudo ./scripts/build-image.sh [options]

Build a bootable Arch Linux ARM image for ClockworkPi uConsole.

Options:
  --model cm5|cm4             Target Compute Module model. Default: cm5
  --image FILE                Output image path. Default: uconsole-arch-cm5.img
  --size SIZE                 Image size for truncate. Default: 8G
  --rootfs FILE               Use an existing Arch Linux ARM rootfs tarball
  --rootfs-url URL            Rootfs tarball URL
  --repo-url URL              Custom pacman repo URL. Default: https://repo.wdk.kr/uconsole-arch/$arch
  --alarm-mirror-url URL      Replace Arch Linux ARM mirrorlist with this mirror URL
  --cache-dir DIR             Download cache directory. Default: .cache under repo root
  --hostname NAME             Hostname written into the image. Default: uconsole
  --extra-package PKG         Install an extra package. Can be used multiple times
  --minimize                  Shrink root filesystem/partition after build
  --shrink-free-space SIZE    Free space to leave in rootfs when minimizing. Default: 768M
  --compress none|zst|xz      Create compressed image next to the raw image. Default: none
  --compression-level N       Compression level. Default: 19
  --verify-rootfs             Verify rootfs tarball with .sig using local GPG keyring
  --keep-mounted              Do not unmount image on failure, for debugging
  -h, --help                  Show this help

Examples:
  sudo ./scripts/build-image.sh --model cm5 --image out/uconsole-arch-cm5.img --size 8G
  sudo ./scripts/build-image.sh --model cm5 --image out/uconsole-arch-cm5.img --size 8G --minimize --compress zst
  sudo ./scripts/build-image.sh --rootfs ./ArchLinuxARM-aarch64-latest.tar.gz
USAGE
}

log_time() { date '+%H:%M:%S'; }
log_info() { printf '[%s] [INFO] %s\n' "$(log_time)" "$*"; }
log_ok() { printf '[%s] [OK]   %s\n' "$(log_time)" "$*"; }
log_warn() { printf '[%s] [WARN] %s\n' "$(log_time)" "$*"; }
log_error() { printf '[%s] [ERR]  %s\n' "$(log_time)" "$*" >&2; }
step() { CURRENT_STEP="$*"; printf '\n[%s] [STEP] %s\n' "$(log_time)" "$*"; }
die() { log_error "$*"; exit 1; }

on_error() {
  local exit_code=$?
  log_error "failed during step: ${CURRENT_STEP}"
  log_error "command: ${BASH_COMMAND}"
  log_error "line: ${BASH_LINENO[0]}, exit code: ${exit_code}"
  exit "$exit_code"
}
trap on_error ERR

cleanup() {
  local exit_code=$?
  trap - ERR

  if [[ "$KEEP_MOUNTED" -eq 1 && "$exit_code" -ne 0 ]]; then
    log_warn "keeping mounts for debugging because --keep-mounted was set"
    log_warn "root mount: ${MOUNT_ROOT:-<none>}"
    log_warn "loop device: ${LOOPDEV:-<none>}"
    exit "$exit_code"
  fi

  if [[ -n "${MOUNT_ROOT:-}" ]]; then
    for mp in \
      "$MOUNT_ROOT/run" \
      "$MOUNT_ROOT/sys" \
      "$MOUNT_ROOT/proc" \
      "$MOUNT_ROOT/dev" \
      "$MOUNT_ROOT/boot" \
      "$MOUNT_ROOT"; do
      if mountpoint -q "$mp" 2>/dev/null; then
        umount "$mp" || umount -l "$mp" || true
      fi
    done
  fi

  if [[ -n "${LOOPDEV:-}" ]]; then
    losetup -d "$LOOPDEV" 2>/dev/null || true
  fi

  if [[ "$exit_code" -eq 0 ]]; then
    log_ok "cleanup completed"
  else
    log_warn "cleanup completed after failure"
  fi
}
trap cleanup EXIT

need_root() {
  [[ "${EUID}" -eq 0 ]] || die "run this script as root: sudo $0"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

abs_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$(pwd -P)" "$path"
  fi
}

size_to_bytes() {
  numfmt --from=iec "$1"
}

align_up() {
  local value="$1"
  local align="$2"
  echo $(( ((value + align - 1) / align) * align ))
}

part_path() {
  local loop="$1"
  local num="$2"

  if [[ -b "${loop}p${num}" ]]; then
    printf '%s\n' "${loop}p${num}"
  elif [[ -b "${loop}${num}" ]]; then
    printf '%s\n' "${loop}${num}"
  else
    die "partition ${num} for ${loop} was not found"
  fi
}

check_loop_support() {
  local loopdev=""
  loopdev="$(losetup -f 2>/dev/null || true)"

  if [[ -z "$loopdev" ]]; then
    log_warn "no usable loop device found; trying to load the loop kernel module"
    if command -v modprobe >/dev/null 2>&1; then
      modprobe loop max_loop=16 2>/dev/null || true
    fi
    udevadm trigger 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    loopdev="$(losetup -f 2>/dev/null || true)"
  fi

  if [[ -n "$loopdev" && -b "$loopdev" ]]; then
    log_ok "loop device support is available: $loopdev"
    return 0
  fi

  if [[ -n "$loopdev" && ! -b "$loopdev" ]]; then
    log_warn "$loopdev is reported by losetup but the block device node does not exist"
  else
    log_warn "losetup did not report a usable loop device"
  fi

  log_warn "creating loop device nodes /dev/loop0 - /dev/loop15"
  for i in $(seq 0 15); do
    if [[ ! -e "/dev/loop$i" ]]; then
      mknod -m 660 "/dev/loop$i" b 7 "$i" 2>/dev/null || true
      chown root:disk "/dev/loop$i" 2>/dev/null || true
    fi
  done

  udevadm settle 2>/dev/null || true
  loopdev="$(losetup -f 2>/dev/null || true)"

  if [[ -n "$loopdev" && -b "$loopdev" ]]; then
    log_ok "loop device support is available after creating nodes: $loopdev"
    return 0
  fi

  die "no usable loop device found. If this is running inside an LXC/container, allow loop devices or run the script on the Proxmox host / a VM. Check: ls -l /dev/loop-control /dev/loop*"
}

check_dependencies() {
  step "checking host dependencies"

  local cmds=(parted losetup partprobe udevadm mkfs.vfat mkfs.ext4 bsdtar curl arch-chroot mount umount mountpoint blkid findmnt truncate awk sed grep numfmt)
  for cmd in "${cmds[@]}"; do
    need_cmd "$cmd"
  done

  if [[ "$(uname -m)" != "aarch64" ]]; then
    need_cmd qemu-aarch64-static
    log_info "non-aarch64 host detected; qemu-aarch64-static will be copied into the rootfs"
  fi

  if [[ "$MINIMIZE" -eq 1 ]]; then
    local minimize_cmds=(e2fsck resize2fs tune2fs)
    for cmd in "${minimize_cmds[@]}"; do
      need_cmd "$cmd"
    done
  fi

  case "$COMPRESS" in
    none) ;;
    zst) need_cmd zstd ;;
    xz) need_cmd xz ;;
    *) die "--compress must be one of: none, zst, xz" ;;
  esac

  check_loop_support
  log_ok "host dependencies look good"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model)
        MODEL="${2:-}"; shift 2 ;;
      --image)
        IMAGE="${2:-}"; shift 2 ;;
      --size)
        IMAGE_SIZE="${2:-}"; shift 2 ;;
      --rootfs)
        ROOTFS_TARBALL="${2:-}"; ROOTFS_TARBALL_USER_SUPPLIED=1; shift 2 ;;
      --rootfs-url)
        ROOTFS_URL="${2:-}"; shift 2 ;;
      --repo-url)
        REPO_URL="${2:-}"; shift 2 ;;
      --alarm-mirror-url)
        ALARM_MIRROR_URL="${2:-}"; shift 2 ;;
      --cache-dir)
        CACHE_DIR="${2:-}"; shift 2 ;;
      --hostname)
        HOSTNAME="${2:-}"; shift 2 ;;
      --extra-package)
        EXTRA_PACKAGES+=("${2:-}"); shift 2 ;;
      --minimize)
        MINIMIZE=1; shift ;;
      --shrink-free-space)
        SHRINK_FREE_SPACE="${2:-}"; shift 2 ;;
      --compress)
        COMPRESS="${2:-}"; shift 2 ;;
      --compression-level)
        COMPRESSION_LEVEL="${2:-}"; shift 2 ;;
      --verify-rootfs)
        VERIFY_ROOTFS=1; shift ;;
      --keep-mounted)
        KEEP_MOUNTED=1; shift ;;
      -h|--help)
        usage; exit 0 ;;
      *)
        die "unknown option: $1" ;;
    esac
  done

  case "$MODEL" in
    cm5|cm4) ;;
    *) die "--model must be cm5 or cm4" ;;
  esac

  if [[ "$IMAGE" == "uconsole-arch-cm5.img" && "$MODEL" == "cm4" ]]; then
    IMAGE="uconsole-arch-cm4.img"
  fi

  IMAGE="$(abs_path "$IMAGE")"
  CACHE_DIR="$(abs_path "$CACHE_DIR")"

  if [[ -z "$ROOTFS_TARBALL" ]]; then
    ROOTFS_TARBALL="$CACHE_DIR/$(basename "$ROOTFS_URL")"
  else
    ROOTFS_TARBALL="$(abs_path "$ROOTFS_TARBALL")"
  fi
}

validate_rootfs_tarball() {
  local tarball="$1"
  log_info "checking rootfs tarball integrity"
  if bsdtar -tf "$tarball" >/dev/null 2>&1; then
    log_ok "rootfs tarball looks valid"
    return 0
  fi
  return 1
}

download_rootfs() {
  step "preparing Arch Linux ARM rootfs tarball"
  mkdir -p "$CACHE_DIR"

  if [[ -f "$ROOTFS_TARBALL" ]]; then
    log_ok "using existing rootfs: $ROOTFS_TARBALL"
    if ! validate_rootfs_tarball "$ROOTFS_TARBALL"; then
      if [[ "$ROOTFS_TARBALL_USER_SUPPLIED" -eq 1 ]]; then
        die "provided rootfs tarball is invalid or incomplete: $ROOTFS_TARBALL"
      fi
      log_warn "cached rootfs tarball is invalid or incomplete; redownloading"
      rm -f "$ROOTFS_TARBALL" "${ROOTFS_TARBALL}.sig"
    fi
  fi

  if [[ ! -f "$ROOTFS_TARBALL" ]]; then
    log_info "downloading rootfs from $ROOTFS_URL"
    curl -fL --retry 3 --connect-timeout 20 -o "${ROOTFS_TARBALL}.part" "$ROOTFS_URL"
    mv "${ROOTFS_TARBALL}.part" "$ROOTFS_TARBALL"
    log_ok "downloaded rootfs: $ROOTFS_TARBALL"
    validate_rootfs_tarball "$ROOTFS_TARBALL" || die "downloaded rootfs tarball is invalid or incomplete"
  fi

  if [[ "$VERIFY_ROOTFS" -eq 1 ]]; then
    local sig_file="${ROOTFS_TARBALL}.sig"
    local sig_url="${ROOTFS_URL}.sig"

    if [[ ! -f "$sig_file" ]]; then
      log_info "downloading rootfs signature from $sig_url"
      curl -fL --retry 3 --connect-timeout 20 -o "$sig_file" "$sig_url"
    fi

    log_info "verifying rootfs signature with local GPG keyring"
    gpg --verify "$sig_file" "$ROOTFS_TARBALL"
    log_ok "rootfs signature verified"
  else
    log_warn "rootfs signature verification is disabled; use --verify-rootfs if your GPG keyring is ready"
  fi
}

create_image_and_partitions() {
  step "creating image and partitions"

  if [[ -e "$IMAGE" ]]; then
    die "output image already exists: $IMAGE"
  fi

  mkdir -p "$(dirname -- "$IMAGE")"
  truncate -s "$IMAGE_SIZE" "$IMAGE"
  [[ -f "$IMAGE" ]] || die "image file was not created: $IMAGE"
  log_ok "created sparse image: $IMAGE ($IMAGE_SIZE)"
  log_info "image file check: $(ls -lh "$IMAGE" | awk '{print $5, $9}')"

  LOOPDEV="$(losetup -Pf --show "$IMAGE")"
  log_info "attached loop device: $LOOPDEV"

  parted -s "$LOOPDEV" mklabel msdos
  parted -s "$LOOPDEV" mkpart primary fat32 1MiB 513MiB
  parted -s "$LOOPDEV" mkpart primary ext4 513MiB 100%
  parted -s "$LOOPDEV" set 1 boot on
  partprobe "$LOOPDEV"
  udevadm settle

  local boot_part root_part
  boot_part="$(part_path "$LOOPDEV" 1)"
  root_part="$(part_path "$LOOPDEV" 2)"

  mkfs.vfat -F 32 -n BOOT "$boot_part"
  mkfs.ext4 -F -L alarm-root "$root_part"
  log_ok "formatted boot=$boot_part, root=$root_part"
}

mount_image() {
  step "mounting image"

  local boot_part root_part
  boot_part="$(part_path "$LOOPDEV" 1)"
  root_part="$(part_path "$LOOPDEV" 2)"

  MOUNT_ROOT="$(mktemp -d /tmp/uconsole-arch-root.XXXXXX)"
  mount "$root_part" "$MOUNT_ROOT"
  mkdir -p "$MOUNT_ROOT/boot"
  mount "$boot_part" "$MOUNT_ROOT/boot"
  log_ok "mounted root at $MOUNT_ROOT"
}

extract_rootfs() {
  step "extracting Arch Linux ARM rootfs"
  bsdtar -xpf "$ROOTFS_TARBALL" -C "$MOUNT_ROOT"
  log_ok "rootfs extracted"
}

install_profiles() {
  step "installing boot profiles"

  [[ -f "$REPO_ROOT/profiles/config.txt" ]] || die "missing $REPO_ROOT/profiles/config.txt"
  [[ -f "$REPO_ROOT/profiles/cmdline.txt" ]] || die "missing $REPO_ROOT/profiles/cmdline.txt"

  install -Dm644 "$REPO_ROOT/profiles/config.txt" "$MOUNT_ROOT/boot/config.txt"
  install -Dm644 "$REPO_ROOT/profiles/cmdline.txt" "$MOUNT_ROOT/boot/cmdline.txt"
  log_ok "installed config.txt and cmdline.txt"
}

write_fstab() {
  step "writing fstab"

  local boot_part root_part boot_uuid root_uuid
  boot_part="$(part_path "$LOOPDEV" 1)"
  root_part="$(part_path "$LOOPDEV" 2)"
  boot_uuid="$(blkid -s UUID -o value "$boot_part")"
  root_uuid="$(blkid -s UUID -o value "$root_part")"

  cat > "$MOUNT_ROOT/etc/fstab" <<EOF_FSTAB
# /etc/fstab generated by scripts/build-image.sh
LABEL=alarm-root  /      ext4  defaults,noatime  0  1
UUID=$boot_uuid   /boot  vfat  defaults,noatime  0  2
EOF_FSTAB

  log_info "root UUID: $root_uuid"
  log_info "boot UUID: $boot_uuid"
  log_ok "fstab written"
}

prepare_chroot_mounts() {
  step "preparing chroot mounts"

  mount --bind /dev "$MOUNT_ROOT/dev"
  mount --bind /proc "$MOUNT_ROOT/proc"
  mount --bind /sys "$MOUNT_ROOT/sys"
  mount --bind /run "$MOUNT_ROOT/run"

  if [[ "$(uname -m)" != "aarch64" ]]; then
    install -Dm755 "$(command -v qemu-aarch64-static)" "$MOUNT_ROOT/usr/bin/qemu-aarch64-static"
  fi

  log_ok "chroot mounts ready"
}

write_chroot_script() {
  step "writing chroot setup script"

  local kernel_pkg mkinitcpio_preset
  case "$MODEL" in
    cm5)
      kernel_pkg="linux-uconsole-cm5-git"
      mkinitcpio_preset="linux-uconsole-cm5-git"
      ;;
    cm4)
      kernel_pkg="linux-uconsole-cm4-git"
      mkinitcpio_preset="linux-uconsole-cm4-git"
      ;;
  esac

  local package_list
  package_list="${BASE_PACKAGES[*]} ${kernel_pkg} wpa_supplicant-raspberrypi ${EXTRA_PACKAGES[*]}"

  cat > "$MOUNT_ROOT/root/uconsole-image-setup.sh" <<EOF_CHROOT
#!/usr/bin/env bash
set -Eeuo pipefail

log_time() { date '+%H:%M:%S'; }
log_info() { printf '[%s] [CHROOT] [INFO] %s\\n' "\$(log_time)" "\$*"; }
log_ok() { printf '[%s] [CHROOT] [OK]   %s\\n' "\$(log_time)" "\$*"; }
log_warn() { printf '[%s] [CHROOT] [WARN] %s\\n' "\$(log_time)" "\$*"; }

log_info "setting hostname"
echo '$HOSTNAME' > /etc/hostname

log_info "relaxing pacman download timeout for slow mirrors"
if ! grep -q '^DisableDownloadTimeout' /etc/pacman.conf; then
  sed -i '/^\[options\]/a DisableDownloadTimeout' /etc/pacman.conf
fi

if [[ -n '$ALARM_MIRROR_URL' ]]; then
  log_info "using custom Arch Linux ARM mirror"
  cp -a /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak.uconsole-image 2>/dev/null || true
  printf 'Server = %s
' '$ALARM_MIRROR_URL' > /etc/pacman.d/mirrorlist
fi

log_info "adding custom pacman repository"
if ! grep -q '^\\[uconsole-arch\\]' /etc/pacman.conf; then
  cat >> /etc/pacman.conf <<'EOF_PACMAN'

[uconsole-arch]
SigLevel = Optional TrustAll
Server = $REPO_URL
EOF_PACMAN
else
  log_warn "uconsole-arch repository already exists in pacman.conf"
fi

log_info "initializing pacman keyring"
pacman-key --init || true
pacman-key --populate archlinuxarm

run_pacman() {
  local attempt
  for attempt in 1 2 3; do
    if pacman --disable-sandbox "\$@"; then
      return 0
    fi
    log_warn "pacman attempt \${attempt}/3 failed"
    rm -f /var/lib/pacman/db.lck
    sleep \$((attempt * 5))
  done
  return 1
}

log_info "refreshing package databases"
run_pacman -Sy --noconfirm

log_info "installing target packages"
run_pacman -S --needed --noconfirm $package_list

log_info "generating initramfs: $mkinitcpio_preset"
mkinitcpio -p '$mkinitcpio_preset'

log_info "enabling services"
systemctl enable NetworkManager.service
systemctl enable sshd.service

log_info "cleaning pacman package cache"
run_pacman -Scc --noconfirm || true

log_ok "chroot setup completed"
EOF_CHROOT

  chmod +x "$MOUNT_ROOT/root/uconsole-image-setup.sh"
  log_ok "chroot setup script written"
}

run_chroot_setup() {
  step "running chroot setup"
  arch-chroot "$MOUNT_ROOT" /bin/bash /root/uconsole-image-setup.sh
  rm -f "$MOUNT_ROOT/root/uconsole-image-setup.sh"
  log_ok "chroot setup finished"
}

unmount_image() {
  step "unmounting image"

  for mp in \
    "$MOUNT_ROOT/run" \
    "$MOUNT_ROOT/sys" \
    "$MOUNT_ROOT/proc" \
    "$MOUNT_ROOT/dev" \
    "$MOUNT_ROOT/boot" \
    "$MOUNT_ROOT"; do
    if mountpoint -q "$mp" 2>/dev/null; then
      umount "$mp"
    fi
  done

  rmdir "$MOUNT_ROOT" 2>/dev/null || true
  MOUNT_ROOT=""
  log_ok "image unmounted"
}

minimize_image() {
  step "minimizing image size"

  local root_part root_start min_blocks block_size free_bytes desired_blocks actual_blocks actual_bytes part_bytes new_end new_image_size
  root_part="$(part_path "$LOOPDEV" 2)"
  free_bytes="$(size_to_bytes "$SHRINK_FREE_SPACE")"

  log_info "checking root filesystem before shrink"
  e2fsck -fy "$root_part"

  log_info "shrinking root filesystem to minimum"
  resize2fs -M "$root_part"
  e2fsck -fy "$root_part"

  min_blocks="$(tune2fs -l "$root_part" | awk -F: '/Block count:/ {gsub(/ /, "", $2); print $2}')"
  block_size="$(tune2fs -l "$root_part" | awk -F: '/Block size:/ {gsub(/ /, "", $2); print $2}')"
  desired_blocks=$(( (min_blocks * block_size + free_bytes + block_size - 1) / block_size ))

  log_info "expanding minimized root filesystem to leave ${SHRINK_FREE_SPACE} free space"
  resize2fs "$root_part" "$desired_blocks"
  e2fsck -fy "$root_part"

  actual_blocks="$(tune2fs -l "$root_part" | awk -F: '/Block count:/ {gsub(/ /, "", $2); print $2}')"
  block_size="$(tune2fs -l "$root_part" | awk -F: '/Block size:/ {gsub(/ /, "", $2); print $2}')"
  actual_bytes=$((actual_blocks * block_size))

  root_start="$(parted -ms "$LOOPDEV" unit B print | awk -F: '$1 == "2" {sub(/B/, "", $2); print $2}')"
  part_bytes="$(align_up $((actual_bytes + 1048576)) 1048576)"
  new_end=$((root_start + part_bytes - 1))
  new_image_size="$(align_up $((new_end + 1)) 1048576)"

  log_info "resizing root partition to $part_bytes bytes"
  parted -s "$LOOPDEV" unit B resizepart 2 "${new_end}B"
  partprobe "$LOOPDEV" || true
  udevadm settle

  log_info "detaching loop device before truncating raw image"
  losetup -d "$LOOPDEV"
  LOOPDEV=""

  truncate -s "$new_image_size" "$IMAGE"
  log_ok "minimized raw image to $(du -h "$IMAGE" | awk '{print $1}') apparent=$(ls -lh "$IMAGE" | awk '{print $5}')"
}

compress_image() {
  if [[ "$COMPRESS" == "none" ]]; then
    return 0
  fi

  step "compressing image"

  case "$COMPRESS" in
    zst)
      COMPRESSED_IMAGE="${IMAGE}.zst"
      log_info "compressing with zstd level ${COMPRESSION_LEVEL}"
      zstd -T0 -"$COMPRESSION_LEVEL" -f "$IMAGE" -o "$COMPRESSED_IMAGE"
      ;;
    xz)
      COMPRESSED_IMAGE="${IMAGE}.xz"
      local xz_level="$COMPRESSION_LEVEL"
      if (( xz_level > 9 )); then
        log_warn "xz supports levels 0-9; using 9 instead of $COMPRESSION_LEVEL"
        xz_level=9
      fi
      log_info "compressing with xz level ${xz_level}"
      xz -T0 -"$xz_level" -k -f "$IMAGE"
      ;;
  esac

  log_ok "compressed image: $COMPRESSED_IMAGE ($(ls -lh "$COMPRESSED_IMAGE" | awk '{print $5}'))"
}

print_summary() {
  step "summary"

  log_ok "image created: $IMAGE"
  log_info "model: $MODEL"
  log_info "custom repo: $REPO_URL"
  log_info "root label: alarm-root"
  log_info "boot config: profiles/config.txt copied to /boot/config.txt"
  log_info "cmdline: profiles/cmdline.txt copied to /boot/cmdline.txt"

  if [[ "$MINIMIZE" -eq 1 ]]; then
    log_info "minimized: yes, rootfs free space left: $SHRINK_FREE_SPACE"
    log_warn "after flashing to a larger SD card, expand the root partition/filesystem to use full capacity"
  fi

  if [[ -n "$COMPRESSED_IMAGE" ]]; then
    log_info "compressed output: $COMPRESSED_IMAGE"
  fi

  log_warn "default Arch Linux ARM credentials may remain unchanged unless you modify them after first boot"
}

main() {
  parse_args "$@"
  need_root
  check_dependencies
  download_rootfs
  create_image_and_partitions
  mount_image
  extract_rootfs
  install_profiles
  write_fstab
  prepare_chroot_mounts
  write_chroot_script
  run_chroot_setup
  unmount_image

  if [[ "$MINIMIZE" -eq 1 ]]; then
    minimize_image
  fi

  if [[ -n "$LOOPDEV" ]]; then
    step "detaching loop device"
    losetup -d "$LOOPDEV"
    LOOPDEV=""
    log_ok "loop device detached"
  fi

  compress_image
  print_summary
}

main "$@"
