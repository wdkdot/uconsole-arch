# Packages

## Pacman Repository

Add the repository to `/etc/pacman.conf`:

```ini
[uconsole-arch]
SigLevel = Optional TrustAll
Server = https://repo.wdk.kr/uconsole-arch/$arch
```

Then refresh databases and install packages with `pacman`:

```bash
sudo pacman -Sy
```

## Kernel Packages

| Package | Target | Page size | Notes |
|---|---|---|---|
| `linux-uconsole-cm5-git` | CM5 | 16K | Default CM5 kernel |
| `linux-uconsole-cm5-4k-git` | CM5 | 4K | Compatibility kernel |
| `linux-uconsole-cm4-git` | CM4 | 4K | CM4 kernel |

Only one uConsole kernel package should be installed at a time because the packages install overlapping boot, DTB, and DTBO paths.

To switch a CM5 installation to the 4K page kernel:

```bash
sudo pacman -S linux-uconsole-cm5-4k-git
```

The 4K package uses the same CM5 boot slot as `linux-uconsole-cm5-git`, so `/boot/config.txt` does not need to be changed.

## Wireless Package

`wpa_supplicant-raspberrypi` is a patched `wpa_supplicant` package for Raspberry Pi / Broadcom brcmfmac Wi-Fi environments.

Unlike the kernel packages, it is currently built manually on the uConsole because the cross-compile setup is inconvenient. During image builds, `scripts/build-image.sh` tries to install this package first. If it is not available in the package repository, the script falls back to the upstream Arch Linux ARM `wpa_supplicant` package so the image build can still complete.

## Build Model

Kernel packages are built automatically with a self-hosted GitHub Actions runner. After successful kernel builds, the pacman repository is regenerated and published to the mirror server.
