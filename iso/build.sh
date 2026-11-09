#!/usr/bin/env bash
# Build the MyLinux installation ISO with mkarchiso.
#
# Usage:
#   sudo ./iso/build.sh            # full build into ./out
#   sudo ./iso/build.sh --clean    # remove work/ and out/ first
#   ./iso/build.sh --check         # pre-flight checks only (no root needed)
#
# Requires: archiso, arch-install-scripts, mtools, libisoburn, squashfs-tools.
# Run this inside the MyLinux-Dev VM, not on the host.
set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/.." && pwd)"

PROFILE="$HERE"
WORKDIR="$ROOT/work"
OUTDIR="$ROOT/out"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
say()  { printf '%s==>%s %s\n' "$BOLD" "$RESET" "$*"; }
warn() { printf '%s!!%s  %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%sxx%s  %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

CLEAN="no"
CHECK_ONLY="no"
while [ $# -gt 0 ]; do
    case "$1" in
        --clean) CLEAN="yes"; shift ;;
        --check) CHECK_ONLY="yes"; shift ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

preflight() {
    say "Pre-flight checks"
    local missing=0
    for c in mkarchiso pacstrap mksquashfs xorriso mcopy; do
        if command -v "$c" >/dev/null 2>&1; then
            printf '   ok    %s\n' "$c"
        else
            printf '   %sMISSING%s %s\n' "$RED" "$RESET" "$c"; missing=1
        fi
    done
    [ -f "$PROFILE/profiledef.sh" ] || die "profiledef.sh not found in $PROFILE"
    [ -d "$PROFILE/airootfs" ] || die "airootfs/ not found in $PROFILE"
    [ -d "$ROOT/packages" ] || die "packages/ not found in $ROOT"

    # Regenerate the live package list from the source of truth.
    "$PROFILE/gen_packages.sh"

    if [ -d /sys/firmware/efi ]; then
        printf '   ok    UEFI firmware detected\n'
    else
        warn "this system is not booted in UEFI mode; the ISO still builds, but the"
        warn "run_archiso boot test and efiboot integration should be validated on UEFI."
    fi

    [ "$missing" -eq 0 ] || die "install the missing tools: pacman -S archiso arch-install-scripts squashfs-tools libisoburn mtools"
    say "Pre-flight OK"
}

# stage_payload copies the installer and the configuration source tree into the
# airootfs so the live image is self-contained. These paths are generated at
# build time and are git-ignored; the repository keeps a single copy of every
# authoring source.
stage_payload() {
    say "Staging installer + source tree into airootfs"
    local dest="$PROFILE/airootfs/usr/share/mylinux"
    rm -rf "$dest"
    install -d "$dest"

    for d in packages desktop system docs branding installer; do
        [ -e "$ROOT/$d" ] || continue
        cp -a "$ROOT/$d" "$dest/"
    done
    # Licensing and top-level docs are useful inside the live image too.
    for f in README.md LICENSE; do
        [ -e "$ROOT/$f" ] && cp -a "$ROOT/$f" "$dest/"
    done

    # The frontend resolves the backend relative to its own location, so the
    # authoritative copy lives at /usr/share/mylinux/installer and a small
    # wrapper in /usr/local/bin points at it.
    rm -rf "$PROFILE/airootfs/usr/local/bin/mylinux-install"
    install -d "$PROFILE/airootfs/usr/local/bin"
    cat > "$PROFILE/airootfs/usr/local/bin/mylinux-install" <<'WRAPPER'
#!/usr/bin/env bash
# MyLinux installer launcher — runs the authoritative frontend from the
# staged source tree.
exec /usr/share/mylinux/installer/frontend/mylinux-install "$@"
WRAPPER
    chmod 0755 "$PROFILE/airootfs/usr/local/bin/mylinux-install"

    # Provide the docs the live motd points at.
    install -d "$PROFILE/airootfs/usr/share/doc/mylinux"
    cp -a "$ROOT/docs/." "$PROFILE/airootfs/usr/share/doc/mylinux/" 2>/dev/null || true

    say "Payload staged"
}

if [ "$CHECK_ONLY" = "yes" ]; then
    preflight
    exit 0
fi

[ "$(id -u)" -eq 0 ] || die "mkarchiso must run as root (use sudo)"
preflight

if [ "$CLEAN" = "yes" ]; then
    say "Cleaning previous build ($WORKDIR, $OUTDIR)"
    rm -rf "$WORKDIR" "$OUTDIR"
fi

stage_payload

rm -rf "$WORKDIR"

mkdir -p "$WORKDIR" "$OUTDIR"

say "Building MyLinux ISO (profile: $PROFILE)"
say "This typically takes 15–40 minutes depending on CPU and network."

mkarchiso -v -w "$WORKDIR" -o "$OUTDIR" "$PROFILE"

say "Build finished"
shopt -s nullglob
isos=("$OUTDIR"/*.iso)
[ "${#isos[@]}" -gt 0 ] || die "mkarchiso reported success but no ISO was produced in $OUTDIR"

for iso in "${isos[@]}"; do
    size="$(du -h "$iso" | cut -f1)"
    printf '%s   %s  (%s)%s\n' "$GREEN" "$iso" "$size" "$RESET"
    ( cd "$OUTDIR" && sha256sum "$(basename "$iso")" > "$(basename "$iso").sha256" )
    printf '   checksum: %s.sha256\n' "$(basename "$iso")"
done

say "Boot-test the result with: sudo ./tests/boot_iso_test.sh ${isos[0]}"
