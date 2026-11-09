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
| `awww`                        | wallpaper daemon                       |

The desktop services are started from `desktop/hypr/conf.d/autostart.lua`, with
system-wide variants in `system/services/`.

## Layer 3 — Desktop

### Hyprland

The compositor configuration is modular:

```
desktop/hypr/
├── hyprland.lua             entry point: loads conf.d modules
├── conf.d/
│   ├── env.lua              Wayland/toolkit environment variables
│   ├── appearance.lua       gaps, borders, blur, rounded corners
│   ├── animations.lua       animation curves and durations
│   ├── input.lua            keyboard, mouse, touchpad, gestures
│   ├── keyboard.lua         installer-owned keyboard layout
│   ├── monitors.lua         display layout
│   ├── windowrules.lua      floating/tiling rules per window class
│   ├── autostart.lua        session programs
│   └── keybinds.lua         keyboard shortcuts
├── hyprlock.conf            lock screen
├── hypridle.conf            idle actions
└── (wallpapers are owned by the launcher's awww backend)
```

Users override a single concern by editing one file in `conf.d/`, without
touching the rest of the configuration. The entry point prepends `conf.d/` to
`package.path` and `require()`s each module, so every module is a plain Lua
script that may be replaced or extended independently.

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
    ├── launcher/             launcher views + backend
    ├── Osd.qml               volume/brightness OSD
    ├── NotificationCenter.qml notification daemon + popup stack
    ├── PowerMenu.qml         session menu
    ├── CalendarPopup.qml     calendar
    └── widgets/              bar widgets
```

`Theme.qml` is the single source of truth for colour, spacing, radius, motion and
typography. The Hyprland palette in `appearance.lua` mirrors the same values, so
the compositor and the shell cannot drift apart.

State flows one way: bar widgets read the system through Quickshell's typed
service bindings (`Quickshell.Networking`, `Quickshell.Bluetooth`,
`Quickshell.Services.UPower`, `Quickshell.Services.Pipewire`) or poll with
`Process`/`StdioCollector`, and publish values into `ShellState`; overlays
observe `ShellState` and their visibility follows it. Quickshell's `IpcHandler`
exposes `qs ipc call mylinux <function>` so Hyprland keybinds can open the
launcher, calendar, power menu, notification center or volume OSD, and clear
notifications.

Every surface declares a `WlrLayershell.namespace`, and `conf.d/windowrules.lua`
matches those namespaces to apply blur. The namespaces are:

| Namespace               | Surface                      | Layer   |
| ----------------------- | ---------------------------- | ------- |
| `mylinux-bar`           | top panel                    | top     |
| `mylinux-launcher`      | application launcher         | overlay |
| `mylinux-calendar`      | calendar popup               | overlay |
| `mylinux-session`       | lock / logout / power menu   | overlay |
| `mylinux-notifications` | notification cards + daemon  | overlay |
| `mylinux-osd`           | volume OSD                   | overlay |

The OSD and notification surfaces are marked `no_screen_share`, so they are
deliberately absent from screencopy (`grim`) output.

Quickshell's `NotificationServer` owns `org.freedesktop.Notifications`; `mako`
is **not** started by `conf.d/autostart.lua` and must not be, or the two
daemons would fight over the name. New notifications are only retained when the
shell sets `notification.tracked = true`, so `NotificationCenter.qml` keeps its
own `ListModel` fed from the `onNotification` signal, which also drives dismissal
and the panel badge count.

### Launcher

The launcher is one overlay that switches between six modes based purely on the
text typed into its single input field:

| Prefix     | Mode          | Behaviour                                        |
| ---------- | ------------- | ------------------------------------------------ |
| (none)     | Applications  | fuzzy search over names and descriptions         |
| `>`        | Applications  | same as above, with an explicit prefix           |
| `=`        | Calculator    | live inline arithmetic, copyable result          |
| `?`        | Web search    | opens the query in the configured provider       |
| `wall:`    | Wallpapers    | live preview grid, applies immediately           |
| `clip:`    | Clipboard     | searchable `cliphist` history, copy and clear    |
| `session:` | Session       | lock, log out, suspend, reboot, shut down        |

The mode is derived from the text alone, so `openLauncher(mode, query)` composes
the prefix into the field and the rest of the view follows. Pure logic lives in
`logic/` (`Modes.js`, `Match.js`, `Calc.js`) so it can be unit-tested outside
QML; the state and process layer is `components/launcher/LauncherBackend.qml`,
and each mode has its own view beside it.

The calculator is a hand-written tokenizer plus recursive-descent parser — there
is no `eval`, `Function` constructor or subprocess, so arbitrary input cannot
execute code. Wallpapers are applied through `awww img`; clipboard history comes
from `cliphist`, with copies written through `Quickshell.clipboardText`. State
(`favorites`, `provider`, `wallpaper`) is persisted atomically to
`~/.local/state/mylinux/launcher.json` via `FileView` with `atomicWrites: true`.
Every external dependency degrades gracefully: if `awww` or `cliphist` is
missing the relevant view explains that instead of failing.

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