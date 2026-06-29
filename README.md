# uconsole-arch

[English](README.md) | [한국어](README.ko.md)

`uconsole-arch` collects the base configuration and package build files for running Arch Linux ARM on the ClockworkPi uConsole.

It focuses on managing the kernel, boot configuration, and Raspberry Pi / Broadcom wireless compatibility package in a reproducible Arch Linux ARM environment.

This project is developed with reference to existing community work around uConsole, including packaging and integration ideas shared by PeterCxy and hardware enablement work from Rex and other contributors.

## Contents

- `linux-uconsole-cm5-git`: kernel package for ClockworkPi uConsole CM5
- `linux-uconsole-cm5-4k-git`: optional CM5 kernel package with 4K memory pages
- `linux-uconsole-cm4-git`: kernel package for ClockworkPi uConsole CM4
- `wpa_supplicant-raspberrypi`: `wpa_supplicant` package for Raspberry Pi / Broadcom brcmfmac environments
- `profiles/`: example boot configuration files for Raspberry Pi CM4/CM5 and uConsole
- `docs/`: planned documentation for installation, boot, and packages

## Installation

### Prebuilt Images

- `uconsole-arch-cm5.img`
  - Image for uConsole with Raspberry Pi CM5
  - Uses the `linux-uconsole-cm5-git` kernel package
  - Uses a 16K memory page kernel
  - Users who need 4K memory pages can replace the kernel package with `linux-uconsole-cm5-4k-git`

- `uconsole-arch-cm4.img`
  - Image for uConsole with Raspberry Pi CM4
  - Uses the `linux-uconsole-cm4-git` kernel package
  - Uses a 4K memory page kernel

Most users should choose the image that matches their Compute Module model.

### Manual Setup

Extract the Arch Linux ARM rootfs to the root partition of an SD card or image, then chroot into that rootfs to install the kernel package and generate the initramfs.

The root filesystem partition label must be set to `alarm-root`. When creating a new ext4 filesystem, set the label at the same time:

```bash
mkfs.ext4 -L alarm-root /dev/ROOT_PARTITION
```

If the ext4 filesystem already exists and only the label needs to be changed, use:

```bash
e2label /dev/ROOT_PARTITION alarm-root
```

For example, if the boot partition is mounted at `/mnt/boot` and the root partition is mounted at `/mnt/root`, the flow is:

```bash
mount /dev/ROOT_PARTITION /mnt/root
mount /dev/BOOT_PARTITION /mnt/boot
```

After extracting the Arch Linux ARM rootfs to `/mnt/root`, copy the profile files from this repository to the boot partition:

```bash
cp profiles/config.txt /mnt/boot/config.txt
cp profiles/cmdline.txt /mnt/boot/cmdline.txt
```

`profiles/config.txt` is a shared configuration file for both CM4 and CM5. At boot time, the appropriate kernel and overlays are selected according to the Compute Module model.

Bind-mount the boot partition so that the rootfs `/boot` points to it, then enter the chroot:

```bash
mount --bind /mnt/boot /mnt/root/boot
arch-chroot /mnt/root
```

For a CM5 image, install the following kernel package:

```bash
pacman -U linux-uconsole-cm5-git-*.pkg.tar.zst
mkinitcpio -p linux-uconsole-cm5-git
```

The default CM5 kernel uses 16K memory pages. To switch a CM5 system to the optional 4K page kernel, replace the kernel package:

```bash
pacman -S linux-uconsole-cm5-4k-git
```

`linux-uconsole-cm5-4k-git` uses the same CM5 boot slot as `linux-uconsole-cm5-git`, so `/boot/config.txt` does not need to be changed. The package installs `/usr/lib/modules/<kernelrelease>/vmlinuz`, which lets the standard `mkinitcpio` pacman hook regenerate the initramfs automatically. To switch back to the default 16K kernel, reinstall `linux-uconsole-cm5-git`.

For a CM4 image, install the following kernel package:

```bash
pacman -U linux-uconsole-cm4-git-*.pkg.tar.zst
mkinitcpio -p linux-uconsole-cm4-git
```

Do not install `linux-uconsole-cm4-git`, `linux-uconsole-cm5-git`, and `linux-uconsole-cm5-4k-git` at the same time because they install overlapping boot and DTB/DTBO paths.

## Scope

This repository focuses on the base system layer required to boot Arch Linux ARM on the uConsole.

- kernel packaging
- boot configuration examples
- device tree and overlay handling
- network compatibility packages

Desktop environments, window managers, and personal UI presets are not included.

## Repository Structure

```text
docs/       Planned documentation
pkgs/       PKGBUILDs and related package files
profiles/   Example boot configuration files
```

## Notes

The files in this repository prioritize device bring-up and packaging information over personal desktop configuration. Environment-specific settings are intended to be added separately on top of this base.

## License

This repository is licensed under the MIT License, unless otherwise noted.

Packaged upstream projects retain their original licenses.
