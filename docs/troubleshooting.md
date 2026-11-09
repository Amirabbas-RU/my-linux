# Troubleshooting MyLinux

This document covers problems you may hit while using, developing or building
MyLinux, and how to diagnose and recover from them.

## Diagnosing anything

Start with the logs:

```bash
mylinux-systeminfo                          # what am I running?
journalctl -b -p warning                    # this boot's warnings
journalctl --user -b                        # user session logs
cat /var/log/mylinux-install.log            # the installer's log (live medium)
```

The installer's log lives in the live environment's `/var/log/`. If you are
already booted into the installed system, the install log is gone unless you
copied it before rebooting.

## Desktop

### Hyprland does not start / black screen after login

**Symptom:** SDDM accepts the login and the screen goes black or returns to SDDM.

**Cause:** Usually a GPU/driver problem, or a Wayland session failing to start.

1. Switch to a TTY (`Ctrl+Alt+F2`) and log in.
2. Check the session log:

   ```bash
   journalctl -b -u sddm
   journalctl -b -u graphical-session.target
   ```

3. Try running Hyprland directly to see the error:

   ```bash
   Hyprland
   ```

**Fix:** On machines without a usable GPU (some VMs), software rendering is
required. Ensure this line is present in `~/.config/hypr/conf.d/env.lua`:

```lua
hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
```

On machines with a real GPU, remove that line to enable hardware acceleration.

### The shell (bar, launcher) does not appear

**Symptom:** A bare Hyprland session with no top bar.

1. Check whether Quickshell is running:

   ```bash
   pgrep -af quickshell
   ```

2. Start it manually to see errors:

   ```bash
   quickshell -p ~/.config/quickshell/shell.qml
   ```

3. Check for QML errors in the output. A missing QML module means the runtime is
   incomplete:

   ```bash
   pacman -Q quickshell qt6-declarative qt6-svg qt6-wayland
   ```

4. Reinstall if needed:

   ```bash
   sudo pacman -S quickshell qt6-declarative qt6-svg qt6-wayland
   ```

**Note:** The shell is also started from `conf.d/autostart.lua`
(`hl.exec_cmd("quickshell -p ...")`). If you start it manually and also have the
autostart line, you will run two instances. Check for duplicates with
`pgrep -af quickshell`.

### The launcher opens but no applications are listed

The launcher reads `.desktop` entries via `DesktopEntries.applications`. If the
list is empty:

- Confirm applications have desktop files:

  ```bash
  ls /usr/share/applications/*.desktop | head
  ```

- Confirm the entries are visible (`NoDisplay=false`).
- Restart the shell after installing new applications; the list is loaded when
  the launcher opens.

### Wallpaper is missing (black background)

The default wallpaper lives at
`/usr/share/mylinux/wallpapers/mylinux-default.png`. If it is missing or
`hyprpaper` is not running:

```bash
pacman -Q hyprpaper || sudo pacman -S hyprpaper
pgrep -af hyprpaper || hyprpaper &
hyprctl hyprpaper listloaded
```

If you installed from a custom build where the wallpaper was not staged,
reinstall from the ISO or copy a wallpaper and update `hyprpaper.conf`.

### Screen locking / idle

`hypridle` handles idle; `hyprlock` draws the lock screen. If the screen never
locks:

```bash
pgrep -af hypridle || hypridle &
```

Check `~/.config/hypr/hypridle.conf` for the timeouts.

If the screen locks immediately, a timeout is set too low — edit `hypridle.conf`.

## Networking

### No network after install

```bash
systemctl status NetworkManager
nmcli device status
nmcli connection show
```

If NetworkManager is not running:

```bash
sudo systemctl enable --now NetworkManager
```

### Wi-Fi is not detected

1. Check the interface exists:

   ```bash
   ip link
   ```

2. Check the firmware loaded:

   ```bash
   dmesg | grep -i firmware | tail
   ```

3. Install additional firmware if the adapter needs it:

   ```bash
   sudo pacman -S linux-firmware
   ```

### DNS does not resolve

```bash
resolvectl status
cat /etc/resolv.conf
```

With NetworkManager, `/etc/resolv.conf` should be managed by it. If it points at
a stale nameserver:

```bash
sudo systemctl restart NetworkManager
```

## Audio

### No sound

```bash
wpctl status
systemctl --user status pipewire wireplumber
```

Check that the default sink is correct and unmuted:

```bash
wpctl status | grep -A3 Sinks
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
wpctl set-volume @DEFAULT_AUDIO_SINK@ 70%
```

If PipeWire is not running:

```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

### Microphone does not work

```bash
wpctl status | grep -A3 Sources
wpctl set-default <source-id>
```

Use `pavucontrol` for a graphical view of the routing.

## Bluetooth

```bash
systemctl status bluetooth
bluetoothctl list
bluetoothctl power on
bluetoothctl scan on
```

If the controller is not listed, the adapter may need firmware:

```bash
dmesg | grep -i bluetooth | tail
sudo pacman -S linux-firmware
```

## Boot

### The system does not boot (GRUB)

At the GRUB menu press `e` to edit the kernel line and check `root=UUID=...`
matches the actual root partition:

```bash
lsblk -f
```

Boot from the live ISO and `arch-chroot` into the installed system to repair:

```bash
mount /dev/<root> /mnt
mount /dev/<esp> /mnt/boot
arch-chroot /mnt
grub-mkconfig -o /boot/grub/grub.cfg
```

### The system does not boot (systemd-boot)

Boot the live medium and check the loader entry:

```bash
cat /boot/loader/entries/mylinux.conf
```

The `root=UUID=` value must match `blkid` for the root partition. Recreate the
entry if needed.

## Installer

### The installer will not select my disk

This is intentional when the disk is protected. The installer refuses any disk
that hosts the running system's `/`, `/boot` or `/efi`, or the live medium.

If you are installing to a disk that also contains the live USB (for example an
internal disk you are booting from), boot the live medium from a *separate* USB
stick so the target disk is free.

### "installs only on UEFI systems"

The live medium was booted in legacy/BIOS mode. Reboot and select the UEFI boot
entry for the USB stick (often prefixed `UEFI:` in the firmware boot menu).

### Installation fails at pacstrap

Almost always network:

```bash
# in another console on the live medium
iwctl                          # join Wi-Fi
ping -c1 archlinux.org
```

Then retry the installer.

### Installation succeeds but the machine boots to firmware settings

The bootloader was installed but the firmware did not record it. Boot the live
medium and re-run the bootloader step, or use `efibootmgr`:

```bash
efibootmgr -v
```

## Building the ISO

| Symptom                          | Fix                                                        |
|----------------------------------|------------------------------------------------------------|
| `mkarchiso: command not found`   | `sudo pacman -S archiso`                                   |
| `target not found: <package>`    | Package removed upstream; update `packages/live.txt` and rerun `./iso/gen_packages.sh`. |
| Build fails in pacstrap          | Stale DB: `sudo pacman -Syu`. Check network.               |
| `no space left on device`        | `work/` needs several GB. `sudo rm -rf work out` and free space. |
| ISO builds but will not boot     | Run `./tests/boot_iso_test.sh`; read the serial log tail.  |

## Testing

### `tests/run_all.sh` reports a package missing

That package no longer exists in the configured repositories. Update
`packages/*.txt` to a current alternative and re-run.

### `tests/boot_iso_test.sh` times out

- The VM may be slow without KVM. Check `ls -l /dev/kvm`.
- Increase the timeout: `--timeout 900`.
- Inspect the serial log it prints; it shows how far the boot reached.

## Recovery

### Chroot into an installed MyLinux system

```bash
# from the live medium
mount /dev/<root-partition> /mnt
mount /dev/<esp-partition> /mnt/boot
arch-chroot /mnt
```

For btrfs installs, mount the `@` subvolume:

```bash
mount -o subvol=@ /dev/<root-partition> /mnt
```

### Reset a forgotten user password

```bash
arch-chroot /mnt
passwd <username>
```

### Restore the default desktop configuration

The shipped defaults live in `/etc/skel/.config/`. To reset a user's desktop
configuration to defaults:

```bash
# back up first
mv ~/.config/hypr ~/.config/hypr.bak
mv ~/.config/quickshell ~/.config/quickshell.bak
cp -a /etc/skel/.config/hypr ~/.config/
cp -a /etc/skel/.config/quickshell ~/.config/
```

Re-login to restart the shell with the defaults.

### Reinstall the bootloader

From the live medium, chrooted:

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=MyLinux --recheck
grub-mkconfig -o /boot/grub/grub.cfg
```

Or with systemd-boot:

```bash
bootctl --esp-path=/boot install
```

## Known limitations

- **UEFI only.** No legacy BIOS boot path.
- **Single-disk installs.** The guided installer does not support LVM, LUKS or
  custom multi-disk layouts yet. (The backend has the building blocks — see
  `installer/backend/lib/partition.sh` — but the frontend does not expose them.)
- **No swap.** The installer does not create a swap partition or swapfile.
- **The installer requires network access** because `pacstrap` fetches packages
  from the Arch mirrors.
- **The live environment is console-only.** The installer is a `dialog` TUI; it
  does not run a graphical installer.
- **Software rendering is enabled by default** on installs where the installer's
  `env.lua` is used. Remove `LIBGL_ALWAYS_SOFTWARE` on hardware with a GPU.

## Getting help

- Documentation: `/usr/share/doc/mylinux/` on an installed system, or `docs/` in
  the repository.
- Issues: https://github.com/Amirabbas-RU/my-linux/issues
- Include `mylinux-systeminfo` output and relevant `journalctl` lines in any bug
  report.