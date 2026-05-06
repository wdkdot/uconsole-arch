# uconsole-arch

[English](README.md) | [한국어](README.ko.md)

Arch Linux ARM for ClockworkPi uConsole with Raspberry Pi CM5.

`uconsole-arch` collects the base configuration and package build files for running Arch Linux ARM on the ClockworkPi uConsole.

It focuses on managing the kernel, boot configuration, and Raspberry Pi / Broadcom wireless compatibility package in a reproducible Arch Linux ARM environment.

This project is developed with reference to existing community work around uConsole, including packaging and integration ideas shared by PeterCxy and the underlying hardware enablement work from Rex and others.

## Contents

- `linux-uconsole-cm5-git`: kernel package for ClockworkPi uConsole CM5
- `wpa_supplicant-raspberrypi`: `wpa_supplicant` package for Raspberry Pi / Broadcom brcmfmac environments
- `profiles/`: example boot configuration files for Raspberry Pi CM5 and uConsole
- `docs/`: installation, boot, and package documentation

## Scope

This repository focuses on the base system layer required to boot Arch Linux ARM on the uConsole.

- kernel packaging
- boot configuration examples
- device tree / overlay handling
- network compatibility packages

Desktop environments, window managers, and personal UI presets are not included.

## Planned Items

- `uconsole-4g-utils`
- `uconsole-audio-switch`

## Repository Structure

```text
docs/       Documentation
pkgs/       PKGBUILDs and related package files
profiles/   Example boot configuration files
```

## Notes

The files in this repository prioritize device bring-up and packaging information over personal desktop configuration. Environment-specific settings are intended to be added separately on top of this base.

## License

This repository is licensed under the MIT License, unless otherwise noted.

Packaged upstream projects retain their original licenses.
