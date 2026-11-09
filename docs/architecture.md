# MyLinux architecture

MyLinux is an Arch Linux–based distribution built from four independent layers.
Each layer can be understood, tested and replaced on its own.

```
   ┌──────────────────────────────────────────────────────────────┐
   │  User interface                                              │
   │  Hyprland (compositor)  +  Quickshell (QML desktop shell)     │
   ├──────────────────────────────────────────────────────────────┤
   │  Session services                                            │
   │  portals · polkit agent · PipeWire · NetworkManager · BlueZ  │
   ├──────────────────────────────────────────────────────────────┤
   │  Base system                                                 │
   │  Arch Linux base + kernel + systemd + bootloader + users      │
   ├──────────────────────────────────────────────────────────────┤
   │  Distribution tooling                                        │
   │  installer · Archiso profile · helper scripts · branding     │
   └──────────────────────────────────────────────────────────────┘
```

## Layer 1 — Base system

MyLinux uses a curated subset of the stock Arch Linux package set
(`packages/base.txt`). Nothing is forked from Arch: the distribution's identity
comes from configuration, the desktop and the installer, not from patching
upstream packages. This keeps updates simple and reproducible.

The base layer provides:

- Kernel (`linux`) plus `linux-firmware` and CPU microcode.
- `systemd` and the standard systemd services (journald, logind).
- `NetworkManager` for wired, wireless and mobile broadband networking.
- `PipeWire` + `wireplumber` for audio, with ALSA/Pulse/JACK compatibility.
- `BlueZ` for Bluetooth.
- `systemd-timesyncd` for time synchronisation.
- Filesystem tools for ext4, btrfs, xfs, FAT and exFAT.
- `GRUB` or `systemd-boot` for UEFI boot.

### Boot flow

```
UEFI firmware
  └─> bootloader (GRUB or systemd-boot) on the EFI system partition
        └─> /boot/vmlinuz-linux + /boot/initramfs-linux.img
              └─> systemd (PID 1)
                    └─> multi-user.target
                          ├─> NetworkManager, bluetooth, timesyncd
                          └─> display-manager (SDDM)  ── on desktop installs
                                └─> Hyprland session
                                      └─> Quickshell shell
```

## Layer 2 — Session services

These run inside the user's Hyprland session:

| Service                       | Purpose                                |
|-------------------------------|----------------------------------------|
| `xdg-desktop-portal-hyprland` | screencast, screenshot, file pickers   |
| `xdg-desktop-portal-gtk`      | GTK file chooser fallback              |
| `hyprpolkitagent`             | graphical privilege escalation prompts |
| `PipeWire` / `wireplumber`    | audio graph and device policy          |
| `NetworkManager` + applet     | networking, VPN, Wi-Fi                 |
| `Blueman`                     | Bluetooth device management            |
| `hypridle` / `hyprlock`       | idle handling and lock screen          |
| `hyprpaper`                   | wallpaper daemon                       |

The desktop services are started from `desktop/hypr/conf.d/autostart.conf`, with
system-wide variants in `system/services/`.

## Layer 3 — Desktop

### Hyprland

The compositor configuration is modular:

```
desktop/hypr/
├── hyprland.conf            entry point: sets variables, sources conf.d
├── conf.d/
│   ├── env.conf             Wayland/toolkit environment variables
│   ├── appearance.conf      gaps, borders, blur, rounded corners
│   ├── animations.conf      animation curves and durations
│   ├── input.conf           keyboard, mouse, touchpad, gestures
│   ├── monitors.conf        display layout
│   ├── windowrules.conf     floating/tiling rules per window class
│   ├── autostart.conf       session programs
│   └── keybinds.conf        keyboard shortcuts
├── hyprlock.conf            lock screen
├── hypridle.conf            idle actions
└── hyprpaper.conf           wallpaper
```

Users override a single concern by editing one file in `conf.d/`, without
touching the rest of the configuration.

### Quickshell

The desktop shell is a QML application (`desktop/quickshell/`). Every surface is
a `PanelWindow` (wlr-layer-shell surface) owned by `shell.qml`:

```
desktop/quickshell/
├── shell.qml                 ShellRoot: instantiates every surface
├── theme/
│   ├── Theme.qml             design tokens (singleton)
│   └── ShellState.qml        shared mutable state
└── components/
    ├── Bar.qml               top panel
    ├── Launcher.qml          application launcher overlay
    ├── Osd.qml               volume/brightness OSD
    ├── NotificationCenter.qml notification daemon + popup stack
    ├── PowerMenu.qml         session menu
    ├── CalendarPopup.qml     calendar
    └── widgets/              bar widgets
```

`Theme.qml` is the single source of truth for colour, spacing, radius, motion and
typography. The Hyprland palette in `appearance.conf` mirrors the same values, so
the compositor and the shell cannot drift apart.

State flows one way: bar widgets poll the system with `Process`/`StdioCollector`
and publish values into `ShellState`; overlays observe `ShellState` and their
visibility follows it. Quickshell's `IpcHandler` exposes
`quickshell ipc call mylinux <function>` so Hyprland keybinds can open the
launcher, calendar or power menu.

## Layer 4 — Distribution tooling

### Installer

```
installer/
├── frontend/mylinux-install     dialog TUI: collects answers, no disk access
├── backend/
│   ├── install_base.sh          orchestrator: partitions, pacstraps, configures
│   └── lib/
│       ├── common.sh            logging, strict mode, guards
│       ├── disk.sh              disk discovery + safety refusals
│       └── partition.sh         GPT layout, formatting, mounting
└── CONFIG.md                    answer-file reference
```

The frontend writes an answer file (`0600`) and hands it to the backend. All
destructive work happens in the backend so the safety gate cannot be bypassed by
a frontend bug.

### Archiso profile

```
iso/
├── profiledef.sh            image name, boot modes, squashfs options
├── packages.x86_64          generated from packages/live.txt
├── pacman.conf              build-time pacman configuration
├── airootfs/                live environment filesystem overlay
├── efiboot/                 systemd-boot entries (the ISO's UEFI loader)
├── gen_packages.sh          generates packages.x86_64
└── build.sh                 wraps mkarchiso + checksums
```

`build.sh` stages the installer and the configuration source tree into
`airootfs/usr/share/mylinux/` so the live image is self-contained, then calls
`mkarchiso`. This is why the same installer code runs in the live environment
and can be tested from a checkout.

## Configuration ownership

| Concern                  | Authoritative location                    |
|--------------------------|-------------------------------------------|
| Desktop defaults         | `desktop/hypr/`, `desktop/quickshell/`    |
| System defaults          | `system/config/`, `system/services/`      |
| Package selection        | `packages/*.txt`                          |
| Distribution identity    | `branding/os-release`, `branding/logo/`   |
| Live image               | `iso/`                                    |
| Installed user overrides | `~/.config/hypr/`, `~/.config/quickshell/` |

The installer copies the repository's configuration into `/etc/skel` and into the
new user's home. A user editing their files never edits the originals, so a
future MyLinux update can replace the shipped defaults without clobbering user
changes.

## Reproducibility

- Every package list lives in `packages/`; the ISO list is generated from it.
- `iso/build.sh` regenerates `packages.x86_64` before building, so the live image
  and the installed system cannot diverge.
- The archiso profile is plain files in this repository, not a modified copy of
  `/usr/share/archiso/configs/releng`.
- Tests (`tests/run_all.sh`) verify package availability against the configured
  repositories, so a build that would fail is caught before `mkarchiso` runs.