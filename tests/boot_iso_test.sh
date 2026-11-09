#!/usr/bin/env bash
# MyLinux ISO boot test — boots the built ISO in an isolated QEMU VM using
# UEFI (OVMF) firmware and software rendering, then verifies that the live
# environment reaches a usable state.
#
# Safety: this test only ever runs QEMU against the given ISO image and a
# throwaway qcow2 overlay in a temporary directory. It never touches a host
# disk, the development VM's disk or the cold backup.
#
# Usage:
#   sudo ./tests/boot_iso_test.sh out/mylinux-*.iso
#   sudo ./tests/boot_iso_test.sh out/mylinux-*.iso --timeout 600
#
# Exit codes: 0 = booted and reached the installer, 1 = failure.
set -Eeuo pipefail

ISO="${1:-}"
shift || true

TIMEOUT=420
MEM=2048
CPUS=2
SERIAL_LOG=""
KEEP="no"

while [ $# -gt 0 ]; do
    case "$1" in
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --mem)     MEM="$2"; shift 2 ;;
        --cpus)    CPUS="$2"; shift 2 ;;
        --serial-log) SERIAL_LOG="$2"; shift 2 ;;
        --keep)    KEEP="yes"; shift ;;
        -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
say()  { printf '%s==>%s %s\n' "$BOLD" "$RESET" "$*"; }
ok()   { printf '%s OK %s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s !! %s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%s XX %s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

[ -n "$ISO" ] || die "usage: $0 <path-to-iso> [--timeout SECONDS]"
[ -f "$ISO" ] || die "ISO not found: $ISO"
ISO="$(cd -- "$(dirname -- "$ISO")" && pwd)/$(basename -- "$ISO")"

command -v qemu-system-x86_64 >/dev/null || die "qemu-system-x86_64 not installed"

# ---- locate OVMF firmware ------------------------------------------------
find_ovmf() {
    local d code vars
    for d in /usr/share/edk2/x64 /usr/share/OVMF /usr/share/edk2-ovmf/x64 /usr/share/qemu; do
        [ -d "$d" ] || continue
        for code in OVMF_CODE.4m.fd OVMF_CODE.fd OVMF_CODE.secboot.4m.fd; do
            if [ -f "$d/$code" ]; then
                vars="${code/CODE/VARS}"
                if [ -f "$d/$vars" ]; then
                    printf '%s\n%s\n' "$d/$code" "$d/$vars"
                    return 0
                fi
            fi
        done
    done
    return 1
}

mapfile -t OVMF < <(find_ovmf)
if [ "${#OVMF[@]}" -lt 2 ]; then
    mapfile -t OVMF < <(
        { find /usr/share -maxdepth 3 -name 'OVMF_CODE*.fd' 2>/dev/null | head -1
          find /usr/share -maxdepth 3 -name 'OVMF_VARS*.fd' 2>/dev/null | head -1; }
    )
fi
[ "${#OVMF[@]}" -ge 2 ] || die "OVMF firmware not found (install edk2-ovmf)"
OVMF_CODE="${OVMF[0]}"
OVMF_VARS_SRC="${OVMF[1]}"
say "OVMF code: $OVMF_CODE"
say "OVMF vars: $OVMF_VARS_SRC"

# ---- scratch workspace ---------------------------------------------------
WORK="$(mktemp -d /tmp/mylinux-boottest.XXXXXX)"
cleanup() {
    if [ "$KEEP" = "yes" ]; then
        warn "keeping test workspace: $WORK"
    else
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT

VARS="$WORK/OVMF_VARS.fd"
cp "$OVMF_VARS_SRC" "$VARS"

DISK="$WORK/disk.qcow2"
qemu-img create -f qcow2 "$DISK" 12G >/dev/null

[ -n "$SERIAL_LOG" ] || SERIAL_LOG="$WORK/serial.log"
: > "$SERIAL_LOG"

# ---- build the QEMU command ---------------------------------------------
# -display none + serial to file: fully headless, works over SSH in the dev VM.
say "Booting ISO in isolated UEFI VM (timeout ${TIMEOUT}s)"

QEMU=(qemu-system-x86_64
    -machine q35,accel=kvm:tcg
    -cpu max
    -smp "$CPUS"
    -m "$MEM"
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
    -drive if=pflash,format=raw,file="$VARS"
    -drive file="$ISO",media=cdrom,readonly=on,format=raw
    -drive file="$DISK",if=virtio,format=qcow2
    -netdev user,id=n0
    -device virtio-net-pci,netdev=n0
    -vga std
    -display none
    -serial "file:$SERIAL_LOG"
    -monitor none
    -no-reboot
    -boot d
)

"${QEMU[@]}" >/dev/null 2>"$WORK/qemu.err" &
QEMU_PID=$!

# ---- wait for the live environment --------------------------------------
# The serial console carries ANSI from both the firmware/bootloader menu and
# the kernel. Strip it and look only for genuine kernel/systemd evidence: the
# bootloader's menu title also says "MyLinux", so it must never count as a
# successful boot.
strip() { tr -d '\r' < "$SERIAL_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b][^\a]*\a//g'; }

markers=(
    "Reached target.*Multi-User"
    "mylinux-live login:"
    "MyLinux live environment"
)
found=""
deadline=$(( $(date +%s) + TIMEOUT ))

while [ "$(date +%s)" -lt "$deadline" ]; do
    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
        warn "QEMU exited before the timeout"
        break
    fi
    snap="$(strip)"
    for m in "${markers[@]}"; do
        if ! printf '%s\n' "$found" | grep -qxF "$m"; then
            if printf '%s\n' "$snap" | grep -qE "$m"; then
                found="$found
$m"
                ok "marker reached: $m"
            fi
        fi
    done
    # Definitive success: systemd reporting the multi-user target. The
    # bootloader menu cannot produce this line, so it cannot false-positive.
    if printf '%s\n' "$snap" | grep -qE "Reached target.*Multi-User"; then
        ok "live environment reached multi-user target"
        break
    fi
    sleep 3
done

# ---- stop the VM ---------------------------------------------------------
if kill -0 "$QEMU_PID" 2>/dev/null; then
    kill -TERM "$QEMU_PID" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "$QEMU_PID" 2>/dev/null || break
        sleep 1
    done
    kill -KILL "$QEMU_PID" 2>/dev/null || true
fi
wait "$QEMU_PID" 2>/dev/null || true

# ---- report --------------------------------------------------------------
say "Serial log: $SERIAL_LOG ($(wc -l < "$SERIAL_LOG" 2>/dev/null || echo 0) lines)"

if [ -s "$WORK/qemu.err" ]; then
    warn "QEMU stderr:"
    sed 's/^/    /' "$WORK/qemu.err" | head -20 >&2
fi

if printf '%s\n' "$found" | grep -qxF "Reached target.*Multi-User"; then
    printf '\n%sPASS%s  the live environment booted and reached multi-user (systemd)\n' "$GREEN" "$RESET"
    exit 0
fi

printf '\n%sFAIL%s  the live environment did not reach multi-user\n' "$RED" "$RESET"
printf '\n--- last 60 lines of the serial console ---\n'
strip | grep -v '^ *$' | tail -60 | sed 's/^/    /'
exit 1