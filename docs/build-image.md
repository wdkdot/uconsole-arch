# Manual Image Build

Bootable images are built manually with `scripts/build-image.sh`.

The image build script creates a bootable Arch Linux ARM image, installs the uConsole boot profiles, adds the package repository, installs the matching kernel package, and enables NetworkManager and sshd.

## Basic CM5 Build

```bash
sudo ./scripts/build-image.sh --model cm5 --image out/uconsole-arch-cm5.img --size 8G
```

## Smaller Distributable Image

Use `--minimize` to shrink the root filesystem and `--compress zst` to create a compressed image next to the raw image.

```bash
sudo ./scripts/build-image.sh --model cm5 --image out/uconsole-arch-cm5.img --size 8G --minimize --compress zst
```

## What the Script Does

- downloads or reuses an Arch Linux ARM aarch64 rootfs tarball
- creates a FAT32 boot partition and an ext4 root partition
- labels the root filesystem as `alarm-root`
- copies `profiles/config.txt` to `/boot/config.txt`
- copies `profiles/cmdline.txt` to `/boot/cmdline.txt`
- adds the `uconsole-arch` pacman repository
- installs the kernel package for the selected model
- installs `wpa_supplicant-raspberrypi` when available, with a fallback to upstream `wpa_supplicant`
- enables NetworkManager and sshd

## Root Filesystem Label

The root filesystem partition label must be `alarm-root` because `profiles/cmdline.txt` uses:

```text
root=LABEL=alarm-root
```

The provided image builder sets this label automatically.

## CM4 Builds

The script supports `--model cm4`.

```bash
sudo ./scripts/build-image.sh --model cm4 --image out/uconsole-arch-cm4.img --size 8G
```
