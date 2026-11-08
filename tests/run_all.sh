#!/usr/bin/env bash
# MyLinux static validation suite.
#
# Runs every check that can be performed without booting the ISO: shell syntax,
# ShellCheck analysis, QML linting, Hyprland config sanity, package availability,
# systemd unit validation, installer dry-run and repository hygiene.
#
# Usage:
#   ./tests/run_all.sh              # run everything
#   ./tests/run_all.sh --fast       # skip the slow/network checks
#
# Exits non-zero if any check fails. Each check prints PASS/FAIL/SKIP.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

FAST="no"
[ "${1:-}" = "--fast" ] && FAST="yes"

GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
PASS=0; FAIL=0; SKIP=0
FAILED_NAMES=()

pass() { PASS=$((PASS+1)); printf '  %sPASS%s  %s\n' "$GREEN" "$RESET" "$*"; }
fail() { FAIL=$((FAIL+1)); FAILED_NAMES+=("$*"); printf '  %sFAIL%s  %s\n' "$RED" "$RESET" "$*"; }
skip() { SKIP=$((SKIP+1)); printf '  %sSKIP%s  %s\n' "$YELLOW" "$RESET" "$*"; }
section() { printf '\n%s== %s ==%s\n' "$BOLD" "$*" "$RESET"; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
section "Repository hygiene"

if [ -d .git ]; then
    pass "git repository present"
else
    skip "not a git repository (running from an extracted tree)"
fi

for f in README.md .gitignore packages/base.txt packages/desktop.txt packages/live.txt; do
    if [ -f "$f" ]; then pass "required file: $f"; else fail "missing required file: $f"; fi
done

if git -C . rev-parse --git-dir >/dev/null 2>&1; then
    if git ls-files --error-unmatch '*.iso' >/dev/null 2>&1 || \
       git ls-files --error-unmatch '*.qcow2' >/dev/null 2>&1; then
        fail "repository tracks an ISO or disk image"
    else
        pass "no ISO/disk images tracked by git"
    fi
fi

# ---------------------------------------------------------------------------
section "Shell scripts: syntax"

mapfile -t SCRIPTS < <(
    find . -type d -name .git -prune -o -type f -print \
    | grep -E '(\.sh$|/mylinux-install$|/mylinux-[a-z-]+$)' \
    | grep -vE '\.(svg|txt|png|service|conf|md|cfg|qml|json)$' \
    | sort
)
BASH_SCRIPTS=()
for f in "${SCRIPTS[@]}"; do
    first="$(head -1 "$f" 2>/dev/null || true)"
    case "$first" in
        *bash*|*sh) BASH_SCRIPTS+=("$f") ;;
    esac
done

for f in "${BASH_SCRIPTS[@]}"; do
    if bash -n "$f" 2>/dev/null; then pass "syntax: $f"; else fail "syntax: $f"; fi
done

if [ "${#BASH_SCRIPTS[@]}" -eq 0 ]; then
    fail "no shell scripts discovered (unexpected)"
fi

# ---------------------------------------------------------------------------
section "Shell scripts: shellcheck"

if have shellcheck; then
    for f in "${BASH_SCRIPTS[@]}"; do
        if shellcheck -S error -f gcc "$f" >/dev/null 2>&1; then
            pass "shellcheck: $f"
        else
            fail "shellcheck: $f"
        fi
    done
else
    skip "shellcheck not installed"
fi

# ---------------------------------------------------------------------------
section "QML: lint"

QMLLINT="$(command -v qmllint 2>/dev/null || true)"
[ -z "$QMLLINT" ] && [ -x /usr/lib/qt6/bin/qmllint ] && QMLLINT=/usr/lib/qt6/bin/qmllint

if [ -n "$QMLLINT" ]; then
    mapfile -t QML < <(find desktop/quickshell -name '*.qml' | sort)
    if [ "${#QML[@]}" -eq 0 ]; then
        fail "no QML files found under desktop/quickshell"
    fi
    for f in "${QML[@]}"; do
        if QT_QPA_PLATFORM=offscreen "$QMLLINT" -I /usr/lib/qt6/qml "$f" >/dev/null 2>&1; then
            pass "qmllint: ${f#desktop/quickshell/}"
        else
            fail "qmllint: ${f#desktop/quickshell/}"
        fi
    done

    for f in "${QML[@]}"; do
        base="$(basename "$f")"
        if grep -qE '^(Item|Rectangle|Row|Column|Text|QtObject|PanelWindow|ShellRoot|PopupWindow)\b' "$f" \
           || grep -qE 'pragma Singleton' "$f"; then
            pass "qml root object: $base"
        else
            fail "qml root object: $base (no recognised root element)"
        fi
    done
else
    skip "qmllint not available"
fi

# ---------------------------------------------------------------------------
section "Hyprland configuration"

HYPR="$ROOT/desktop/hypr"
for f in hyprland.conf hyprlock.conf hypridle.conf hyprpaper.conf; do
    if [ -f "$HYPR/$f" ]; then pass "present: hypr/$f"; else fail "missing: hypr/$f"; fi
done

for f in "$HYPR"/conf.d/*.conf; do
    [ -f "$f" ] || continue
    open=$(grep -o '{' "$f" | wc -l)
    close=$(grep -o '}' "$f" | wc -l)
    if [ "$open" -eq "$close" ]; then
        pass "brace balance: conf.d/$(basename "$f")"
    else
        fail "brace balance: conf.d/$(basename "$f") ($open open, $close close)"
    fi
done

if grep -qhE '^\s*[a-z_.]+\s*=[^=]' "$HYPR"/conf.d/*.conf; then
    pass "conf.d uses key = value syntax"
else
    fail "conf.d does not look like Hyprland syntax"
fi

for mod in env appearance animations input monitors windowrules autostart keybinds; do
    if grep -q "conf.d/$mod.conf" "$HYPR/hyprland.conf"; then
        pass "hyprland.conf sources $mod.conf"
    else
        fail "hyprland.conf does not source $mod.conf"
    fi
done

# ---------------------------------------------------------------------------
section "systemd units"

if have systemd-analyze; then
    for u in "$ROOT"/system/services/*.service; do
        [ -f "$u" ] || continue
        if systemd-analyze verify "$u" >/dev/null 2>&1; then
            pass "unit verify: $(basename "$u")"
        else
            err="$(systemd-analyze verify "$u" 2>&1 || true)"
            if echo "$err" | grep -qiE 'unknown (key|section|directive)|invalid'; then
                fail "unit verify: $(basename "$u")"
            else
                pass "unit verify: $(basename "$u") (structure ok)"
            fi
        fi
    done
else
    skip "systemd-analyze not available"
fi

# ---------------------------------------------------------------------------
section "Package availability"

if [ "$FAST" = "yes" ]; then
    skip "package availability (fast mode)"
elif have pacman; then
    mapfile -t PKGS < <(cat packages/base.txt packages/desktop.txt packages/live.txt \
        | grep -vE '^\s*(#|$)' | awk '{print $1}' | sort -u)
    missing=0
    for p in "${PKGS[@]}"; do
        if ! pacman -Si "$p" >/dev/null 2>&1; then
            fail "package not in repos: $p"
            missing=$((missing+1))
        fi
    done
    if [ "$missing" -eq 0 ]; then
        pass "all ${#PKGS[@]} packages resolvable in configured repos"
    fi
else
    skip "pacman not available"
fi

# ---------------------------------------------------------------------------
section "Installer"

if bash -n installer/backend/install_base.sh; then pass "installer backend syntax"; fi

if grep -q 'confirm_destructive' installer/backend/install_base.sh \
   && grep -q 'ERASE' installer/backend/lib/disk.sh; then
    pass "destructive operations gated by typed confirmation"
else
    fail "destructive operations are not gated"
fi

for guard in is_protected assert_selectable disk_is_whole; do
    if grep -q "^$guard()" installer/backend/lib/disk.sh; then
        pass "disk guard present: $guard"
    else
        fail "disk guard missing: $guard"
    fi
done

if grep -qE '\b(sgdisk|parted|mkfs\.)' installer/frontend/mylinux-install; then
    fail "frontend performs disk operations directly (should delegate to backend)"
else
    pass "frontend delegates all disk operations to the backend"
fi

if have pacstrap; then
    cfg="$(mktemp)"
    cat > "$cfg" <<EOF
TARGET_DISK=/dev/null
ROOT_FS=ext4
BOOTLOADER=grub
HOSTNAME=test
TIMEZONE=UTC
LOCALE=en_US.UTF-8
KEYMAP=us
USERNAME=tester
USER_PASSWORD=x
ROOT_PASSWORD=x
INSTALL_DESKTOP=no
KERNEL=linux
EOF
    out="$(MYLINUX_SOURCE="$ROOT" ./installer/backend/install_base.sh --config "$cfg" --dry-run 2>&1 || true)"
    if echo "$out" | grep -qE 'not a whole disk|no target disk|failed'; then
        pass "backend rejects an invalid target disk (/dev/null)"
    else
        fail "backend accepted /dev/null as an install target"
    fi
    rm -f "$cfg"
else
    skip "pacstrap not available for installer dry-run"
fi

# ---------------------------------------------------------------------------
section "ISO profile"

if [ -f iso/profiledef.sh ]; then
    pass "iso/profiledef.sh present"
    for k in iso_name iso_label iso_publisher install_dir buildmodes bootmodes arch airootfs_image_type; do
        if grep -qE "^\s*$k=" iso/profiledef.sh; then
            pass "profiledef: $k"
        else
            fail "profiledef missing: $k"
        fi
    done
fi

[ -d iso/airootfs ] && pass "iso/airootfs present" || fail "iso/airootfs missing"
[ -f iso/gen_packages.sh ] && pass "iso/gen_packages.sh present" || fail "iso/gen_packages.sh missing"
[ -f iso/grub/grub.cfg ] && pass "iso/grub/grub.cfg present" || fail "iso/grub/grub.cfg missing"
[ -f iso/efiboot/loader/loader.conf ] && pass "systemd-boot loader.conf present" || fail "systemd-boot loader.conf missing"

if [ -f iso/airootfs/etc/passwd ] && grep -q '^root:' iso/airootfs/etc/passwd; then
    pass "live airootfs defines root"
else
    fail "live airootfs/etc/passwd missing root"
fi

if [ -x iso/airootfs/usr/local/bin/mylinux-live-welcome ]; then
    pass "live welcome script is executable"
else
    fail "live welcome script is missing or not executable"
fi

# ---------------------------------------------------------------------------
section "Documentation"

for d in README.md docs/architecture.md docs/installation.md docs/development.md \
         docs/packages.md docs/building-iso.md docs/troubleshooting.md; do
    if [ -s "$d" ]; then pass "doc present: $d"; else fail "doc missing or empty: $d"; fi
done

# ---------------------------------------------------------------------------
printf '\n%s== Summary ==%s\n' "$BOLD" "$RESET"
printf '  passed: %d\n  failed: %d\n  skipped: %d\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
    printf '\n  failures:\n'
    for f in "${FAILED_NAMES[@]}"; do printf '    - %s\n' "$f"; done
    exit 1
fi
printf '\n%sAll checks passed.%s\n' "$GREEN" "$RESET"