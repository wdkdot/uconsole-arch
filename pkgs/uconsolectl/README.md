# uconsolectl

Simple CLI for uConsole CM5 hardware status and 4G control.

## Scope (initial version)

Implemented commands:

- `uconsolectl 4g on`
- `uconsolectl 4g off`
- `uconsolectl 4g reset`
- `uconsolectl 4g status [--json]`
- `uconsolectl battery [--json]`
- `uconsolectl battery raw`
- `uconsolectl status [--json]`

Not included in this version:

- power profiles
- SD card guard/doctor
- Waybar-specific output
- Hyprconsole-specific output
- daemon mode
- 4G autostart management
- full APN/profile management

## Install

Build/install with makepkg in this directory:

```bash
cd pkgs/uconsolectl
makepkg -si
```

Installed paths:

- `/usr/bin/uconsolectl`
- `/etc/uconsolectl/uconsolectl.conf`

Packaging note: local package inputs live at the package directory top level,
matching the convention used by the other local PKGBUILDs in this repository.

## Configuration

Configuration file:

- `/etc/uconsolectl/uconsolectl.conf`

Default values:

```ini
[4g]
power_gpio=19
reset_gpio=14
modem_index=auto
scan_timeout_sec=10

[battery]
uevent_path=/sys/class/power_supply/axp20x-battery/uevent
```

`modem_index=auto` selects the first modem from `mmcli -L`.

## 4G Notes

`4g on/off/reset` typically need root privileges because GPIO and modem control may require elevated permissions.

Examples:

```bash
sudo uconsolectl 4g on
uconsolectl 4g status
sudo uconsolectl 4g off
```

## Battery Notes

Battery status reads a single uevent file and parses key values.

```bash
uconsolectl battery
uconsolectl battery raw
uconsolectl status
```

## Dependencies

Required:

- python
- modemmanager

Optional:

- networkmanager (for better connection summary)
