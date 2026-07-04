# Installation

## Prebuilt Image

Currently, the prebuilt image is available for CM5 only.

| Image | Status | Target | Notes |
|---|---|---|---|
| `uconsole-arch-cm5.img` | Available | CM5 | Default image, 16K page kernel |
| `uconsole-arch-cm4.img` | Planned | CM4 | Kernel package available, image not published yet |
| `uconsole-arch-cm5-4k.img` | Not provided | CM5 | Install `linux-uconsole-cm5-4k-git` after boot if needed |

Flash `uconsole-arch-cm5.img` to a microSD card or eMMC target with your preferred image writing tool, then boot the uConsole CM5.

## Default Login

The image keeps the default Arch Linux ARM credentials.

- User: `alarm`
- Password: `alarm`
- Root password: `root`

Change both passwords after first boot:

```bash
passwd
sudo passwd root
```

## First Update

The package repository is already added by the image build script. After booting, update with:

```bash
sudo pacman -Syu
```

## Manual Image Build

Bootable images are built manually with `scripts/build-image.sh`. See [build-image.md](build-image.md) for details.
