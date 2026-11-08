# Installing MyLinux

This document covers installing MyLinux from the live ISO with the guided
installer, plus what the installer does at each step.

## Requirements

| Item            | Requirement                                            |
|-----------------|--------------------------------------------------------|
| Firmware        | **UEFI** (BIOS/legacy is not supported yet)            |
| CPU             | x86_64, 1 GHz or faster                                |
| RAM             | 2 GiB to run the live environment, 4 GiB recommended   |
| Disk            | 12 GiB minimum, 20 GiB+ recommended                    |
| Network         | Internet access while installing (packages are fetched)|

> ⚠️ **The installer erases the disk you select.** Read the confirmation screen
> carefully. MyLinux refuses to touch the disk that hosts the running system, its
> `/boot` or `/efi`, or the live USB/ISO medium, but you are still responsible for
> choosing the right target.

## 1. Boot the live medium

1. Write the ISO to a USB stick:

   ```bash
   sudo dd if=out/mylinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

   Replace `/dev/sdX` with the USB device (**not** a partition such as
   `/dev/sdX1`). You can also use `balenaEtcher` or `ventoy`.

2. Boot the target machine from the USB stick, selecting the UEFI boot entry.

3. The MyLinux welcome screen appears on the first virtual console and starts the
   installer automatically after a few seconds.

## 2. Guided installer

The installer walks through these screens:

| Screen            | What it asks                                                     |
|-------------------|------------------------------------------------------------------|
| Welcome           | Confirms you want to proceed.                                    |
| Language          | System locale (e.g. `en_US.UTF-8`).                              |
| Timezone          | Region, then city. Written to `/etc/localtime`.                  |
| Keyboard          | Console keymap. Also applied to Hyprland.                        |
| Disk              | Target disk. **Protected disks are labelled and refused.**       |
| Partitioning      | Whole-disk erase or quick signature wipe.                        |
| Filesystem        | `ext4`, `btrfs` (with subvolumes) or `xfs`.                      |
| Bootloader        | `GRUB` or `systemd-boot`.                                        |
| User              | Hostname, username, user password, root password.                |
| Desktop           | Install Hyprland + Quickshell, or a base system only.            |
| Summary           | Review + one final confirmation before anything is written.      |
| Progress          | Live log of partitioning, pacstrap, configuration, bootloader.   |
| Finish            | Reboot into the new system.                                      |

### What the backend does

1. **Partition** (`lib/partition.sh`): writes a GPT with a 512 MiB EFI system
   partition (`MYLINUX-ESP`) and a root partition (`MYLINUX-ROOT`).
2. **Format**: FAT32 on the ESP; ext4/btrfs/xfs on root. btrfs additionally
   creates `@`, `@home`, `@log` and `@pkg` subvolumes.
3. **Mount**: root at `/mnt/mylinux-target`, ESP at `.../boot`.
4. **Base install**: `pacstrap` with `packages/base.txt` (+ `packages/desktop.txt`
   when the desktop is selected).
5. **fstab**: generated with UUIDs by `genfstab`.
6. **Configure**: timezone, locale, keymap, hostname, users, sudoers, os-release,
   branding, `mkinitcpio`, services.
7. **Desktop**: copies `desktop/hypr` and `desktop/quickshell` into `/etc/skel`
   and the new user's home; sets the Hyprland keyboard layout; enables SDDM.
8. **Bootloader**: GRUB (`grub-install` + `grub-mkconfig`) or systemd-boot with a
   generated loader entry.
9. **Unmount** and finish.

Every command is written to `/var/log/mylinux-install.log` in the live
environment, which the progress screen tails.

## 3. First boot

After rebooting, SDDM presents the MyLinux login. Log in as the user created
during installation.

On first login the shell starts and you get:

- The MyLinux top bar: brand, workspaces, clock/calendar, tray, status cluster.
- `SUPER + D` or `SUPER + R` opens the application launcher.
- `SUPER + Return` opens a terminal (`kitty`).
- `SUPER + L` locks the screen.
- `SUPER + Escape` opens the session menu (lock/logout/reboot/shutdown).

### Useful commands

```bash
mylinux-systeminfo     # what am I running?
sudo mylinux-update    # refresh mirrors and upgrade
mylinux-welcome        # the first-run helper
```

## 4. Unattended installation

The backend accepts an answer file for scripted installs:

```bash
sudo MYLINUX_SOURCE=/usr/share/mylinux \
     /usr/share/mylinux/installer/backend/install_base.sh --config /root/answers.conf
```

See [`installer/CONFIG.md`](../installer/CONFIG.md) for every variable. The typed
confirmation prompt is still required — `--config` does **not** disable the
destructive-operation gate.

To review what an answer file would do without touching a disk:

```bash
sudo .../install_base.sh --config answers.conf --dry-run
```

## 5. Troubleshooting the install

| Symptom                              | Likely cause / fix                                  |
|--------------------------------------|-----------------------------------------------------|
| "installs only on UEFI systems"      | Booted in legacy mode. Select the UEFI boot entry.  |
| Disk missing from the list           | No disk detected; check `lsblk` in another console. |
| Selected disk is refused             | It hosts the running system/live medium. Choose another. |
| `pacstrap` fails                     | No network. Run `iwctl` to join Wi-Fi, then retry.  |
| Bootloader install fails             | ESP not mounted at `/boot`. Check the install log.  |
| System boots to a black screen       | Check `LIBGL_ALWAYS_SOFTWARE` in `conf.d/env.conf`; see `docs/troubleshooting.md`. |

See [`docs/troubleshooting.md`](troubleshooting.md) for more.