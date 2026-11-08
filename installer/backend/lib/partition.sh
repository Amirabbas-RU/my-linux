#!/usr/bin/env bash
# MyLinux installer — partitioning library (UEFI / GPT).
#
# Creates a two-partition layout on a whole disk:
#   p1  EFI system partition   512 MiB   FAT32   /boot  (also /efi)
#   p2  Linux root (filesystem selected by the user)  remainder  /
#
# Nothing here runs until assert_selectable + confirm_destructive have passed.
# All writes happen through `run` so the install log records every sgdisk call.

# partition_suffix <device> — nvme/mmc devices need a "p" before the number.
partition_suffix() {
    case "$1" in
        *[0-9]) printf 'p' ;;   # nvme0n1, mmcblk0
        *)      printf '' ;;    # sda, vda
    esac
}

# wipe_disk <device> [mode] — remove signatures and the partition table.
# mode=whole : aggressively zero the beginning and end of the disk
# mode=quick : just remove signatures and zap the GPT/MBR tables (default)
wipe_disk() {
    local dev="$1" mode="${2:-quick}"
    # Unmount anything currently using the disk so the wipe can succeed.
    local mnt
    while IFS= read -r mnt; do
        [ -n "$mnt" ] || continue
        run "unmounting $mnt" umount -Rf "$mnt" || true
    done < <(lsblk -nro MOUNTPOINT "$dev" | grep -v '^$' || true)

    if is_mounted "$dev"; then
        die "$dev is still in use and could not be unmounted"
    fi

    run "removing filesystem signatures on $dev" wipefs -af "$dev" || true
    if [ "$mode" = "whole" ]; then
        run "zeroing partition table area of $dev" bash -c \
            "dd if=/dev/zero of='$dev' bs=1M count=8 status=none conv=fsync"
    fi
    run "zapping GPT/MBR on $dev" sgdisk --zap-all "$dev"
}

# create_partitions <device> <esp_mib>
create_partitions() {
    local dev="$1" esp_mib="${2:-512}"
    local sfx; sfx="$(partition_suffix "$dev")"

    run "creating GPT + EFI system partition" \
        sgdisk --clear \
               -n "1:0:+${esp_mib}M" -t "1:ef00" -c "1:MYLINUX-ESP" \
               -n "2:0:0"            -t "2:8300" -c "2:MYLINUX-ROOT" \
               "$dev"

    # Let the kernel re-read the new table.
    run "probing partition table" partprobe "$dev"
    udevadm settle

    printf '%s%s1\n%s%s2\n' "$dev" "$sfx" "$dev" "$sfx"
}

# format_filesystems <esp> <root> <root_fs>
format_filesystems() {
    local esp="$1" root="$2" root_fs="${3:-ext4}"

    run "formatting EFI partition $esp (FAT32)" mkfs.fat -F32 -n MYLINUX-ESP "$esp"

    case "$root_fs" in
        ext4)
            run "formatting root $root (ext4)" mkfs.ext4 -F -L MYLINUX-ROOT "$root" ;;
        btrfs)
            run "formatting root $root (btrfs)" mkfs.btrfs -f -L MYLINUX-ROOT "$root"
            mkdir -p "$MYLINUX_TARGET"
            run "mounting btrfs root" mount "$root" "$MYLINUX_TARGET"
            run "creating btrfs subvolumes" btrfs subvolume create "$MYLINUX_TARGET/@"
            run "creating btrfs subvolumes" btrfs subvolume create "$MYLINUX_TARGET/@home"
            run "creating btrfs subvolumes" btrfs subvolume create "$MYLINUX_TARGET/@log"
            run "creating btrfs subvolumes" btrfs subvolume create "$MYLINUX_TARGET/@pkg"
            run "unmounting btrfs root" umount "$MYLINUX_TARGET" ;;
        xfs)
            run "formatting root $root (xfs)" mkfs.xfs -f -L MYLINUX-ROOT "$root" ;;
        *)
            die "unsupported root filesystem: $root_fs" ;;
    esac
}

# mount_target <esp> <root> <root_fs>
mount_target() {
    local esp="$1" root="$2" root_fs="${3:-ext4}"

    run "creating target mountpoint" mkdir -p "$MYLINUX_TARGET"

    case "$root_fs" in
        btrfs)
            run "mounting btrfs @ subvolume" \
                mount -o "subvol=@,compress=zstd,noatime" "$root" "$MYLINUX_TARGET"
            run "creating /home" mkdir -p "$MYLINUX_TARGET/home"
            run "creating /var/log" mkdir -p "$MYLINUX_TARGET/var/log"
            run "creating /var/cache/pacman/pkg" mkdir -p "$MYLINUX_TARGET/var/cache/pacman/pkg"
            run "mounting @home" mount -o "subvol=@home,compress=zstd,noatime" "$root" "$MYLINUX_TARGET/home"
            run "mounting @log" mount -o "subvol=@log,compress=zstd,noatime" "$root" "$MYLINUX_TARGET/var/log"
            run "mounting @pkg" mount -o "subvol=@pkg,compress=zstd,noatime" "$root" "$MYLINUX_TARGET/var/cache/pacman/pkg" ;;
        ext4|xfs)
            run "mounting root" mount "$root" "$MYLINUX_TARGET" ;;
    esac

    run "creating ESP mountpoint" mkdir -p "$MYLINUX_TARGET/boot"
    run "mounting EFI partition" mount "$esp" "$MYLINUX_TARGET/boot"
    run "creating /efi compatibility mount" mkdir -p "$MYLINUX_TARGET/efi"
}

# unmount_target — recursively unmount the target, safe to call repeatedly.
unmount_target() {
    if mountpoint -q "$MYLINUX_TARGET" 2>/dev/null; then
        for m in "$MYLINUX_TARGET/var/cache/pacman/pkg" "$MYLINUX_TARGET/var/log" \
                 "$MYLINUX_TARGET/home" "$MYLINUX_TARGET/boot" "$MYLINUX_TARGET/efi" \
                 "$MYLINUX_TARGET"; do
            if mountpoint -q "$m" 2>/dev/null; then
                umount -R "$m" || umount -Rl "$m" || true
            fi
        done
    fi
    true
}
