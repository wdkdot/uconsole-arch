# Installation

## Prebuilt Image

Prebuilt images are available for CM4 and CM5.

| Image | Status | Target | Notes |
|---|---|---|---|
| `uconsole-arch-cm5.img` | Available | CM5 | Default image, 16K page kernel |
| `uconsole-arch-cm4.img` | Available | CM4 | CM4 image, 4K page kernel |
| `uconsole-arch-cm5-4k.img` | Not provided | CM5 | Install `linux-uconsole-cm5-4k-git` after boot if needed |

Flash the image for your Compute Module to a microSD card or eMMC target with your preferred image writing tool, then boot the uConsole.

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
