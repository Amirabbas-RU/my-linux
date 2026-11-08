# MyLinux installer configuration reference

The MyLinux installer backend (`installer/backend/install_base.sh`) reads a
plain shell fragment when invoked with `--config FILE`. This file documents
every variable it understands and the values it accepts.

> The answer file contains **passwords**. It is written with mode `0600` by the
> frontend and removed once the install finishes. Never commit an answer file.

## Variables

| Variable          | Required | Default    | Description |
|-------------------|----------|------------|-------------|
| `TARGET_DISK`     | yes      | —          | Whole disk to install to, e.g. `/dev/vda`. Must be a whole disk, never a partition. |
| `ROOT_FS`         | no       | `ext4`     | Root filesystem: `ext4`, `btrfs` or `xfs`. |
| `BOOTLOADER`      | no       | `grub`     | `grub` or `systemd-boot` (UEFI). |
| `HOSTNAME`        | no       | `mylinux`  | System hostname. |
| `TIMEZONE`        | no       | `UTC`      | Any zoneinfo name, e.g. `Europe/Berlin`, `Asia/Tehran`. |
| `LOCALE`          | no       | `en_US.UTF-8` | System locale, generated in `/etc/locale.gen`. |
| `KEYMAP`          | no       | `us`       | Console keymap written to `/etc/vconsole.conf`. |
| `USERNAME`        | yes      | —          | Primary user account name. |
| `USER_PASSWORD`   | yes      | —          | Password for `USERNAME`. |
| `ROOT_PASSWORD`   | yes      | —          | Password for `root`. |
| `INSTALL_DESKTOP` | no       | `yes`      | `yes` installs Hyprland + Quickshell; `no` is a base system only. |
| `KERNEL`          | no       | `linux`    | Kernel package. |
| `ESP_SIZE_MIB`    | no       | `512`      | Size of the EFI system partition in MiB. |
| `WIPE_MODE`       | no       | `whole`    | `whole` zeroes the start of the disk; `quick` only removes signatures. |

## Example

```sh
TARGET_DISK=/dev/vdb
ROOT_FS=btrfs
BOOTLOADER=systemd-boot
HOSTNAME=demo
TIMEZONE=Europe/Berlin
LOCALE=en_US.UTF-8
KEYMAP=de
USERNAME=ada
USER_PASSWORD='correct horse battery staple'
ROOT_PASSWORD='another strong password'
INSTALL_DESKTOP=yes
KERNEL=linux
ESP_SIZE_MIB=512
WIPE_MODE=whole
```

## Modes

```
install_base.sh --config FILE    # guided/unattended install using FILE
install_base.sh --interactive    # minimal prompt-driven install
install_base.sh --check          # validate environment + config, touch nothing
install_base.sh --dry-run        # validate and print the plan, touch no disks
```

`--dry-run` is useful in CI and for reviewing what an answer file would do.

## Safety model

1. **Hard refusals** (`lib/disk.sh`): the installer will not accept a disk that
   hosts the running system's `/`, `/boot` or `/efi`, the live installation
   medium, any partition (only whole disks), or any loop/zram/md/dm device.
2. **Typed confirmation**: before any write the backend prints the disk inventory
   and requires the user to type the device's basename *and* the word `ERASE`.
3. **Re-validation**: the disk is re-checked immediately after confirmation in
   case conditions changed.
4. The frontend cannot bypass step 1–3; the destructive gate lives in the
   backend.
