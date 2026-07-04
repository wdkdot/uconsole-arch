# uconsole-arch

[English](README.md) | [한국어](README.ko.md)

Ready-to-flash Arch Linux ARM images and kernel packages for the ClockworkPi uConsole.

This repository provides:

- ready-to-flash CM4 and CM5 images
- CM4, CM5, and CM5 4K kernel packages through a pacman repository
- boot profiles for ClockworkPi uConsole CM4/CM5
- a Raspberry Pi / Broadcom wireless compatibility package

> Prebuilt images are available for CM4 and CM5.
> A separate CM5 4K image is not provided; install `linux-uconsole-cm5-4k-git` after boot if needed.

Installed systems can receive kernel updates through `pacman`; a new image is not required for every kernel package release.

## Quick Start

1. Download the image for your Compute Module: `uconsole-arch-cm4.img` or `uconsole-arch-cm5.img`.
2. Flash it to a microSD card or eMMC target.
3. Boot the uConsole.
4. Log in with the default Arch Linux ARM credentials.
5. Change the default passwords.
6. Update with `pacman`.

```bash
sudo pacman -Syu
```

## Available Images

| Image | Status | Target | Notes |
|---|---|---|---|
| `uconsole-arch-cm5.img` | Available | CM5 | Default image, 16K page kernel |
| `uconsole-arch-cm4.img` | Available | CM4 | CM4 image, 4K page kernel |
| `uconsole-arch-cm5-4k.img` | Not provided | CM5 | Install `linux-uconsole-cm5-4k-git` after boot if needed |

## Default Login

This image currently keeps the default Arch Linux ARM credentials.

- User: `alarm`
- Password: `alarm`
- Root password: `root`

Change both passwords after first boot:

```bash
passwd
sudo passwd root
```

## Package Repository

The prebuilt image already includes this repository in `/etc/pacman.conf`, so image users can update directly with `pacman`.

For a manual installation or an existing Arch Linux ARM system, add the repository to `/etc/pacman.conf`:

```ini
[uconsole-arch]
SigLevel = Optional TrustAll
Server = https://repo.wdk.kr/uconsole-arch/$arch
```

Then install or update packages with `pacman`.

## Kernel Packages

Kernel packages are built from the uConsole-enabled Raspberry Pi kernel maintained by Rex: <https://github.com/ak-rex/ClockworkPi-linux>

| Package | Target | Page size | Notes |
|---|---|---|---|
| `linux-uconsole-cm5-git` | CM5 | 16K | Default CM5 kernel |
| `linux-uconsole-cm5-4k-git` | CM5 | 4K | Compatibility kernel |
| `linux-uconsole-cm4-git` | CM4 | 4K | CM4 kernel |

Do not install `linux-uconsole-cm4-git`, `linux-uconsole-cm5-git`, and `linux-uconsole-cm5-4k-git` at the same time. They install overlapping boot, DTB, and DTBO paths.

To switch a booted CM5 system to the 4K page kernel:

```bash
sudo pacman -S linux-uconsole-cm5-4k-git
```

The CM5 4K package uses the same CM5 boot slot as the default CM5 kernel, so `/boot/config.txt` does not need to be changed.

## Wireless Package

`wpa_supplicant-raspberrypi` is a patched `wpa_supplicant` package for Raspberry Pi / Broadcom brcmfmac Wi-Fi environments. The image builder installs it when available and falls back to the upstream Arch Linux ARM `wpa_supplicant` package if needed.

## Build and Release Model

- Kernel packages are built automatically with a self-hosted GitHub Actions runner.
- The pacman repository is regenerated and published to the mirror server after successful kernel builds.
- `wpa_supplicant-raspberrypi` is built manually on the uConsole because cross-compiling it is currently inconvenient.
- Bootable images are built manually with `scripts/build-image.sh`.
- New images are not produced for every kernel update because installed systems can update through `pacman`.

## Manual Image Build

Manual image build instructions are documented in [docs/build-image.md](docs/build-image.md).

## Repository Structure

```text
docs/       Installation, image build, package, and boot notes
pkgs/       PKGBUILDs and related package files
profiles/   Boot configuration files copied into images
scripts/    Kernel package and image build scripts
```

## Credits

This project is developed with reference to existing community work around uConsole, including packaging and integration ideas shared by PeterCxy and hardware enablement work from Rex and other contributors.

## License

This repository is licensed under the MIT License, unless otherwise noted.

Packaged upstream projects retain their original licenses.
