# Developing MyLinux

Everything in this repository is plain text: shell, QML, Hyprland configuration
and Archiso profile files. There is no build daemon, no package repository and no
compiler for the distribution itself — the ISO is produced by `mkarchiso` from
the files in this tree.

## Development environment

The supported development environment is an Arch Linux VM with:

```bash
sudo pacman -S --needed \
    base-devel git \
    archiso arch-install-scripts \
    dosfstools gptfdisk parted squashfs-tools libisoburn mtools \
    qemu-base edk2-ovmf \
    dialog shellcheck \
    qt6-declarative qt6-svg qt6-wayland quickshell \
    hyprland hyprpaper hyprlock hypridle hyprpolkitagent \
    pipewire wireplumber networkmanager bluez bluez-utils
```

This is exactly what `packages/base.txt` and `packages/desktop.txt` describe, so
installing both lists plus the build/test tools reproduces the maintainer's
environment.

## Repository layout

```
docs/                 Architecture, installation, development, build docs
desktop/hypr/         Hyprland configuration (modular)
desktop/quickshell/   Quickshell QML desktop shell
system/scripts/       Helper/maintenance scripts installed to /usr/local/bin
system/services/      systemd units and service configuration
system/config/        Base system configuration templates
packages/             Curated package lists (base / desktop / live)
installer/            MyLinux installer (dialog frontend + backend)
iso/                  Archiso profile and live ISO configuration
tests/                Automated validation and ISO boot test
branding/             Original MyLinux identity, logo, wallpaper
```

## Editing the desktop

### Theme

Change `desktop/quickshell/theme/Theme.qml` for colour, spacing, radius, motion
and typography. Mirror any palette change in
`desktop/hypr/conf.d/appearance.conf` so the compositor matches.

### Adding a shell surface

1. Create the component in `desktop/quickshell/components/`, rooted at
   `PanelWindow` (or `Item`/`Row`/`Column` for sub-components).
2. Instantiate it in `shell.qml` and give it the `shellState` it needs.
3. Expose it through the `IpcHandler` at the bottom of `shell.qml` if a keybind
   should open it.
4. Add a keybind in `desktop/hypr/conf.d/keybinds.conf`, e.g.
   `bind = $mainMod, X, exec, quickshell ipc call mylinux toggleWhatever`.

### Validating QML

```bash
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmllint \
    -I /usr/lib/qt6/qml desktop/quickshell/shell.qml
```

The test suite runs this for every QML file.

### Running the shell live

```bash
quickshell -p ~/.config/quickshell/shell.qml
```

To develop against the repository copy without installing it:

```bash
quickshell -p "$PWD/desktop/quickshell/shell.qml"
```

`shell.qml` is the entry point; Quickshell treats the given directory as the
config root.

## Editing the installer

The installer is split so the safety-critical code is small and auditable:

- `installer/backend/lib/disk.sh` — the only place that decides whether a disk is
  acceptable. If you touch disk selection, change it here and add a test.
- `installer/backend/lib/partition.sh` — GPT layout, formatting, mounting.
- `installer/backend/install_base.sh` — the orchestration order.
- `installer/frontend/mylinux-install` — the dialog TUI; **never** performs disk
  operations.

### Testing the installer without a disk

```bash
sudo MYLINUX_SOURCE="$PWD" \
     ./installer/backend/install_base.sh --config /tmp/answers.conf --dry-run
```

This validates the configuration and prints the plan; it does not touch any disk.

To exercise the real install path safely, install into a **scratch disk**, never
the development VM's own disk:

```bash
qemu-img create -f qcow2 /tmp/scratch.qcow2 12G
# attach it to a VM or a loop device and install onto that device only
```

## Editing the ISO profile

- `iso/profiledef.sh` — image metadata and boot modes.
- `packages/live.txt` — the live environment package set (source of truth;
  `iso/packages.x86_64` is generated).
- `iso/airootfs/` — files overlaid onto the live environment.
- `iso/efiboot/` — the ISO's systemd-boot menu (`loader.conf` + entries).
- `iso/build.sh` — orchestrates `mkarchiso`.

After changing `packages/live.txt`, regenerate and validate:

```bash
./iso/gen_packages.sh
./iso/build.sh --check
```

## Running the tests

```bash
# fast: no network / no package lookups
./tests/run_all.sh --fast

# full: validates every package against the configured repositories
./tests/run_all.sh
```

The suite runs: shell syntax, shellcheck, QML lint, Hyprland structure, systemd
unit verification, package availability, installer safety checks and ISO profile
checks. It exits non-zero if anything fails.

Boot-testing the ISO (requires nested virtualization):

```bash
sudo ./tests/boot_iso_test.sh out/mylinux-*.iso
```

## Code style

- **Shell**: `bash`, `set -Eeuo pipefail`, shellcheck-clean at error level.
  Quote variables, use `local`, prefer `printf` over `echo` for data.
- **QML**: 4-space indent, `required property` for injected dependencies, no
  hardcoded colours — always use `Theme.*` and `ShellState`.
- **Configuration**: one concern per file; `conf.d/` modules sourced from a thin
  entry point.

## Git workflow

```bash
git status
git add <files>
git commit -m "desktop: add calendar popup"
```

- Commit logical milestones, not everything at once.
- Never commit ISOs, disk images, answer files or secrets (`.gitignore` covers the
  common cases).
- Do not push without authorisation.

## Reproducing the maintainer's setup

1. Install Arch Linux in a VM (UEFI).
2. Install the packages listed above.
3. `git clone` this repository.
4. `./tests/run_all.sh` to confirm the tree is healthy.
5. `sudo ./iso/build.sh` to build the ISO.
6. `sudo ./tests/boot_iso_test.sh out/mylinux-*.iso` to boot-test it.

If all four steps succeed you have a working MyLinux development environment.