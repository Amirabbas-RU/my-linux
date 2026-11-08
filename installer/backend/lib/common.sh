#!/usr/bin/env bash
# MyLinux installer — shared shell library.
#
# Sourced by install_base.sh and every lib/*.sh helper. Provides logging,
# strict-mode helpers, root/UEFI guards and a small set of wrappers used by
# the destructive parts of the install. Nothing here performs partitioning or
# writes to a disk on its own.

# ---- strict mode ---------------------------------------------------------
set -Eeuo pipefail

# ---- paths ---------------------------------------------------------------
# MYLINUX_SOURCE is the tree containing packages/, desktop/, system/, branding/.
# In the live ISO this is /usr/share/mylinux (populated by the Archiso profile).
# When developing from a checkout the orchestrator overrides it.
: "${MYLINUX_SOURCE:=/usr/share/mylinux}"
: "${MYLINUX_LOG:=/var/log/mylinux-install.log}"
: "${MYLINUX_TARGET:=/mnt/mylinux-target}"

# ---- colours -------------------------------------------------------------
if [ -t 1 ]; then
    C_RESET=$'\033[0m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'
else
    C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi

# ---- logging -------------------------------------------------------------
_log() {
    local level="$1"; shift
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s [%s] %s\n' "$ts" "$level" "$*" | tee -a "$MYLINUX_LOG" >&2
}

info()  { _log "INFO " "$@"; }
warn()  { _log "$(printf '%sWARN%s ' "$C_YELLOW" "$C_RESET")" "$@"; }
error() { _log "$(printf '%sERROR%s' "$C_RED" "$C_RESET")" "$@"; }
step()  { _log "STEP " "$(printf '%s%s%s' "$C_BOLD" "$*" "$C_RESET")"; }

# ---- failure handling ----------------------------------------------------
die() {
    error "$*"
    exit 1
}

# on_error prints the failing line and command. Combined with `set -E` this
# makes an unexpected failure easy to locate in the install log.
on_error() {
    local code=$?
    error "command failed (exit $code) at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
    exit "$code"
}
trap on_error ERR

# ---- guards --------------------------------------------------------------
require_root() {
    [ "$(id -u)" -eq 0 ] || die "the MyLinux installer must run as root"
}

require_uefi() {
    [ -d /sys/firmware/efi ] || die \
        "MyLinux currently installs only on UEFI systems (no /sys/firmware/efi)."
}

require_source() {
    [ -d "$MYLINUX_SOURCE" ] || die "install source tree not found: $MYLINUX_SOURCE"
    for d in packages desktop system branding; do
        [ -d "$MYLINUX_SOURCE/$d" ] || die "install source is missing '$d': $MYLINUX_SOURCE"
    done
}

# ---- command wrapper -----------------------------------------------------
# run <description> <command...> — logs the description, runs the command
# verbatim, and dies if it fails. Use for every side-effecting command so the
# install log explains what the installer was doing when something broke.
run() {
    local desc="$1"; shift
    info "running: $desc"
    "$@" >>"$MYLINUX_LOG" 2>&1 || die "failed: $desc"
}

# ---- small utilities -----------------------------------------------------
# is_mounted <device-or-path>
is_mounted() {
    findmnt -rn -S "$1" >/dev/null 2>&1 || findmnt -rn -T "$1" >/dev/null 2>&1
}

# confirm_typed <expected> <prompt> — requires the user to type a value
# verbatim. Used to gate destructive operations.
confirm_typed() {
    local expected="$1" prompt="$2" answer
    printf '%s\n' "$prompt"
    printf 'type %s to confirm: ' "$expected"
    read -r answer
    [ "$answer" = "$expected" ]
}
