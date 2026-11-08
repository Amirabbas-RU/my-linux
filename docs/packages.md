# MyLinux packages

MyLinux's package selection lives in three files under `packages/`. They are the
single source of truth: the installer reads them, and the live ISO package list
is generated from `live.txt`.

| File                 | Used by                                   |
|-----------------------|-------------------------------------------|
| `packages/base.txt`   | Installer, base phase (`pacstrap`)        |
| `packages/desktop.txt`| Installer, desktop phase (layered on base)|
| `packages/live.txt`   | Archiso live environment                  |

Every package is from the official Arch Linux repositories (core, extra,
multilib). There are no AUR packages and no forked packages.

## Base system

The base set is deliberately small. It contains only what is needed to boot,
manage users, network, produce audio, use Bluetooth, keep time and install/upgrade.

| Group                | Packages (representative)                                      |
|----------------------|----------------------------------------------------------------|
| Core system          | `base`, `linux`, `linux-firmware`, `systemd`, `sudo`, `pacman` |
| Microcode            | `amd-ucode`, `intel-ucode`                                     |
| Boot                 | `grub`, `efibootmgr`, `os-prober`                              |
| Filesystems          | `e2fsprogs`, `dosfstools`, `exfatprogs`, `btrfs-progs`, `xfsprogs`, `parted`, `gptfdisk` |
| Encryption/volumes   | `cryptsetup`, `lvm2`                                           |
| Networking           | `networkmanager`, `network-manager-applet`, `iwd`, `wpa_supplicant`, `openssh` |
| DNS                  | `bind` (for `dig`/`host` tooling), systemd-resolved via NetworkManager |
| Audio                | `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `pipewire-jack`, `wireplumber`, `alsa-utils`, `pavucontrol`, `pamixer` |
| Bluetooth            | `bluez`, `bluez-utils`                                         |
| Time                 | `systemd-timesyncd`                                            |
| Hardware             | `pciutils`, `usbutils`, `dmidecode`                            |
| Utilities            | `vim`, `nano`, `less`, `man-db`, `htop`, `tree`, `rsync`, `jq` |
| Fonts                | `noto-fonts`, `noto-fonts-emoji`, `ttf-jetbrains-mono-nerd`, `fontconfig` |

## Desktop

The desktop set is layered on the base set when the user selects the MyLinux
desktop during installation.

| Group            | Packages (representative)                                      |
|------------------|----------------------------------------------------------------|
| Compositor       | `hyprland`, `hyprpicker`, `wayland-protocols`, `wayland-utils` |
| Portals          | `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` |
| Shell runtime    | `quickshell`, `qt6-declarative`, `qt6-svg`, `qt6-base`, `qt6-5compat`, `qt6-multimedia`, `qt6-wayland` |
| Authentication   | `polkit`, `polkit-gnome`, `hyprpolkitagent`                    |
| Display manager  | `sddm`                                                         |
| Terminals        | `kitty`, `foot`                                                |
| Screenshots      | `grim`, `slurp`, `swappy`                                      |
| Clipboard        | `wl-clipboard`, `cliphist`                                     |
| Brightness/media | `brightnessctl`, `playerctl`                                   |
| Networking UI    | `network-manager-applet`, `nm-connection-editor`, `blueman`    |
| Notifications    | `libnotify`, `mako`                                            |
| Wallpaper        | `hyprpaper`, `awww`, `matugen`                                 |
| Lock/idle        | `hyprlock`, `hypridle`                                         |
| Fonts            | `ttf-jetbrains-mono-nerd`, `noto-fonts`, `noto-fonts-emoji`, `ttf-dejavu` |
| Icons/cursors    | `papirus-icon-theme`, `adwaita-cursors`                        |
| Theming tools    | `gtk3`, `qt6ct`, `nwg-look`                                    |
| Audio/Bluetooth  | `pipewire`, `wireplumber`, `pavucontrol`, `bluez`, `bluez-utils` |

## Live environment

The live set is richer than the installed base on purpose: the live image must
partition disks, mount filesystems, run `pacstrap` and drive the installer.

Notable additions over the base set: `arch-install-scripts`, `dialog`, `squashfs-tools`,
`zstd`, `xz`, `terminus-font`, `git`. See `packages/live.txt` for the exact list.

## Why these packages?

- **No `linux-lts` by default.** New hardware support matters more for a new
  distribution; users can install `linux-lts` afterwards.
- **`iwd` alongside `NetworkManager`.** NetworkManager can use `iwd` as its
  Wi-Fi backend, and `iwd` gives the live environment `iwctl`.
- **Both `polkit-gnome` and `hyprpolkitagent`.** The latter is the Hyprland-native
  agent; the former is a fallback for sessions that do not start it.
- **`pipewire-jack`.** Provides JACK compatibility without a full JACK server,
  which many audio applications expect.
- **`ahww` not bundled.** MyLinux ships `hyprpaper` for wallpapers; `awww`
  (the maintained successor to `swww`) is available for animated wallpapers.

## Auditing the package set

`tests/run_all.sh` verifies every package in all three lists resolves in the
configured repositories:

```bash
./tests/run_all.sh    # the "Package availability" section
```

A missing package is a build blocker and fails the test.

## Adding a package

1. Add it to the appropriate list (`base.txt`, `desktop.txt` or `live.txt`).
2. Run `./tests/run_all.sh --fast` for syntax/structure checks.
3. Run `./tests/run_all.sh` to confirm the package resolves.
4. If it is a desktop runtime dependency, also make sure it is started or
   configured where appropriate (`desktop/hypr/conf.d/autostart.conf` or a
   systemd unit under `system/services/`).