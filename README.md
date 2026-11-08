# MyLinux

An independent, reproducible, installable Arch Linux–based distribution
featuring the **Hyprland** Wayland compositor and a custom **Quickshell** desktop.

MyLinux is not a thin wrapper around another distribution's design. It ships its
own visual identity, its own desktop shell, its own installer and its own Archiso
build profile, all maintained in this repository.

```
  __  __       _     _     _
 |  \/  |_   _| |   (_)_ __  _   ___  __
 | |\/| | | | | |   | | '_ \| | | \ \/ /
 | |  | | |_| | |___| | | | | |_| |>  <
 |_|  |_|\__, |_____|_|_| |_|\__,_/_/\_\
         |___/
```

## Highlights

| Area        | What MyLinux provides                                            |
|-------------|------------------------------------------------------------------|
| Base        | Minimal, reproducible Arch Linux base with a curated package set |
| Desktop     | Hyprland + Quickshell shell (panel, launcher, notifications, OSD)|
| Identity    | Original MyLinux theme, palette, wallpapers and branding          |
| Services    | PipeWire, BlueZ, NetworkManager, systemd-timesyncd, portals      |
| Installer   | Guided TUI installer with UEFI support and destructive safeguards |
| ISO         | Reproducible Archiso profile producing a bootable live image      |
| QA          | Automated static checks + nested-VM boot testing of the ISO       |

## Repository layout

```
docs/                 Architecture, installation, development, build docs
desktop/hypr/         Hyprland compositor configuration
desktop/quickshell/   Quickshell (QML) desktop shell
system/scripts/       Distribution helper and maintenance scripts
system/services/      systemd units and service configuration
system/config/        Base system configuration templates
packages/             Curated package lists (base / desktop / live)
installer/            MyLinux installer (frontend + backend)
iso/                  Archiso profile and live ISO branding
tests/                Automated validation and ISO boot tests
branding/             Logos, wallpapers and theme assets
```

## Quick start

Develop inside the `MyLinux-Dev` VM, then build the ISO:

```bash
# 1. clone
mkdir -p ~/Projects && cd ~/Projects
git clone https://github.com/Amirabbas-RU/my-linux.git MyLinux
cd MyLinux

# 2. build the live ISO (requires archiso, ~15-30 min)
sudo ./iso/build.sh

# 3. boot-test the ISO in a nested VM
sudo ./tests/boot_iso_test.sh out/mylinux-*.iso
```

See `docs/building-iso.md` for details and `docs/installation.md` for install steps.

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — system and desktop architecture
- [`docs/installation.md`](docs/installation.md) — installing MyLinux
- [`docs/development.md`](docs/development.md) — development workflow
- [`docs/packages.md`](docs/packages.md) — package selection rationale
- [`docs/building-iso.md`](docs/building-iso.md) — building the ISO
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — common problems

## Status

MyLinux is under active development. See the final report and
`docs/troubleshooting.md` for current limitations.

## License

See `LICENSE`.
