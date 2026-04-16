# uconsole-arch

Arch Linux ARM for ClockworkPi uConsole with Raspberry Pi CM5.

`uconsole-arch` is a repository for building and organizing the base Arch Linux ARM environment for the ClockworkPi uConsole on Raspberry Pi CM5.

The goal of this project is to provide a clean and maintainable foundation for booting Arch Linux ARM on the uConsole, with package-based handling of the kernel, boot-related files, and hardware support components.

This project is developed with reference to existing community work around uConsole, including packaging and integration ideas shared by PeterCxy and the underlying hardware enablement work from Rex and others.

## Goals

- Boot Arch Linux ARM on ClockworkPi uConsole with Raspberry Pi CM5
- Package the required kernel and related files in a maintainable Arch-style form
- Organize uConsole-specific hardware support as reusable packages
- Keep the base system clean and easy to build on top of

## Scope

This repository focuses on the base system layer:

- kernel packaging
- boot configuration examples
- device tree / overlay handling
- network compatibility packages
- optional hardware helper packages for uConsole-specific features

Desktop environments, window managers, and personal user interface presets are intended to live separately from this repository.

## Planned Packages

The package list may change over time, but the initial structure is planned around components like:

- `linux-uconsole-cm5-git`
- `wpa_supplicant-raspberrypi-git`
- `uconsole-4g-utils`
- `uconsole-audio-switch`

## Repository Structure

```text
docs/       Documentation
pkgs/       PKGBUILDs and related package files
profiles/   Example boot configuration files
scripts/    Build and repository helper scripts
```

## Notes

This repository is intended to be a clean base for uConsole Arch Linux ARM work. Higher-level desktop or UI-specific configurations can be developed in separate repositories on top of this foundation.

## License

TBD
