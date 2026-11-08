#!/usr/bin/env bash
# MyLinux installer — disk safety library.
#
# Every operation that can destroy data funnels through this file. It exists so
# that the rules protecting the user's disks live in one auditable place.
#
# Hard refusals (always, no override):
#   * the disk holding the running system (/)
#   * the disk holding /boot or /efi
#   * the disk backing the installer's own live medium
#   * any device without a whole-disk size (partitions are never targets)
#
# Soft refusals (require explicit typed confirmation):
#   * a disk that already contains a partition table or filesystems

# ---- discovery -----------------------------------------------------------
# list_install_disks — emit "name|size_bytes|model|tran|removable" one per
# line for every whole, non-loop, non-rom block device.
list_install_disks() {
    lsblk -dno NAME,SIZE,TYPE,MODEL,TRAN,RM | awk '$3=="disk" {print}' | while read -r name size type model tran rm; do
        case "$name" in
            loop*|sr*|zram*) continue ;;
        esac
        local bytes
        bytes="$(blockdev --getsize64 "/dev/$name" 2>/dev/null || echo 0)"
        printf '/dev/%s|%s|%s|%s|%s\n' "$name" "$bytes" "${model:-unknown}" "${tran:-unknown}" "${rm:-0}"
    done
}

# human_size <bytes>
human_size() {
    numfmt --to=iec --suffix=B "${1:-0}" 2>/dev/null || echo "${1:-0}B"
}

# _device_of_mount <path> — resolve the whole-disk device backing a mountpoint.
_device_of_mount() {
    local path="$1" src disk
    src="$(findmnt -nro SOURCE -T "$path" 2>/dev/null | head -1)" || return 1
    [ -n "$src" ] || return 1
    case "$src" in
        /dev/*) ;;
        *) return 1 ;;   # tmpfs, overlay, network, etc. cannot be destroyed here
    esac
    disk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -1)"
    if [ -n "$disk" ]; then
        printf '/dev/%s\n' "$disk"
    else
        printf '%s\n' "$src"
    fi
}

# protected_disks — every whole disk that must never be selected.
protected_disks() {
    local d
    for mp in / /boot /efi /boot/efi /run/archiso/bootmnt /run/mylinux/bootmnt; do
        if [ -e "$mp" ]; then
            d="$(_device_of_mount "$mp" || true)"
            [ -n "$d" ] && printf '%s\n' "$d"
        fi
    done
    # the live medium's parent device, if archiso recorded it
    if [ -r /run/archiso/bootmnt ]; then
        local src disk
        src="$(findmnt -nro SOURCE -T /run/archiso/bootmnt 2>/dev/null | head -1)"
        if [ -n "$src" ]; then
            disk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -1)"
            [ -n "$disk" ] && printf '/dev/%s\n' "$disk"
        fi
    fi
    true
}

# is_protected <device> — true when the device backs the running system/live medium.
is_protected() {
    local dev="$1" p
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        if [ "$p" = "$dev" ]; then
            return 0
        fi
    done < <(protected_disks | sort -u)
    return 1
}

# disk_is_whole <device>
disk_is_whole() {
    [ -b "$1" ] || return 1
    [ "$(lsblk -dno TYPE "$1" 2>/dev/null)" = "disk" ]
}

# disk_has_data <device> — true if a partition table or filesystems exist.
disk_has_data() {
    local dev="$1"
    if blkid "$dev" >/dev/null 2>&1; then
        return 0
    fi
    local parts
    parts="$(lsblk -nro NAME "$dev" 2>/dev/null | tail -n +2)"
    [ -n "$parts" ] && return 0
    return 1
}

# disk_summary <device> — human-readable inventory for the confirmation screen.
disk_summary() {
    local dev="$1"
    echo "Device:  $dev"
    echo "Model:   $(lsblk -dno MODEL "$dev" 2>/dev/null | sed 's/ *$//')"
    echo "Size:    $(lsblk -dno SIZE "$dev" 2>/dev/null)"
    echo "Bus:     $(lsblk -dno TRAN "$dev" 2>/dev/null)"
    if disk_has_data "$dev"; then
        echo
        echo "!! This disk already contains partitions or filesystems:"
        lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$dev" | sed 's/^/   /'
    else
        echo
        echo "This disk appears to be empty."
    fi
    echo
    echo "Existing signatures:"
    wipefs --no-act "$dev" 2>/dev/null | sed 's/^/   /' || echo "   (none)"
}

# ---- guards --------------------------------------------------------------
# assert_selectable <device> — hard refusal checks. Dies on any failure.
assert_selectable() {
    local dev="$1"

    [ -n "$dev" ] || die "no target disk given"
    [ -e "$dev" ] || die "target disk does not exist: $dev"
    disk_is_whole "$dev" || die "$dev is not a whole disk (never install to a partition)"

    case "$(basename "$dev")" in
        loop*|sr*|zram*|md*|dm-*)
            die "$dev is a virtual/removable pseudo-device and cannot be a target" ;;
    esac

    if is_protected "$dev"; then
        die "$dev hosts the running system, its /boot or /efi, or the live medium.
    Refusing to touch it. This protects the machine you are installing from."
    fi
}

# confirm_destructive <device> — the human gate before we write anything.
# Returns 0 only when the user types the disk's basename twice-verified.
confirm_destructive() {
    local dev="$1" base answer
    base="$(basename "$dev")"

    printf '\n'
    printf '================= DESTRUCTIVE OPERATION =================\n'
    disk_summary "$dev"
    printf '\n'
    printf 'ALL DATA on %s will be ERASED and MyLinux installed on it.\n' "$dev"
    printf 'This cannot be undone.\n'
    printf '=========================================================\n\n'

    printf 'Type the device name to confirm (e.g. %s), or leave blank to abort: ' "$base"
    read -r answer
    if [ "$answer" != "$base" ]; then
        return 1
    fi

    printf 'Type ERASE to proceed with the wipe: '
    read -r answer
    [ "$answer" = "ERASE" ]
}
