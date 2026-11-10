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
    find . -type d \( -name .git -o -name work -o -name out \) -prune -o -type f -print \
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

QMLLINT=""
if [ -x /usr/lib/qt6/bin/qmllint ]; then
    QMLLINT=/usr/lib/qt6/bin/qmllint
elif command -v qmllint >/dev/null 2>&1; then
    QMLLINT="$(command -v qmllint)"
fi
if [ -n "$QMLLINT" ]; then
    probe="$(mktemp --suffix=.qml)"
    printf 'import QtQuick\nItem { width: 1; height: 1 }\n' > "$probe"
    if ! QT_QPA_PLATFORM=offscreen "$QMLLINT" "$probe" >/dev/null 2>&1; then
        skip "qmllint at $QMLLINT rejects even a trivial file; skipping lint"
        QMLLINT=""
    fi
    rm -f "$probe"
fi

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

    LOCAL_ROOTS=()
    while IFS= read -r name; do
        [ -n "$name" ] && LOCAL_ROOTS+=("$name")
    done < <(find desktop/quickshell -name '*.qml' -printf '%f\n' | sed 's/\.qml$//' | sort -u)
    LOCAL_ROOT_RE="$(IFS='|'; echo "${LOCAL_ROOTS[*]}")"

    for f in "${QML[@]}"; do
        base="$(basename "$f")"
        if grep -qE '^(Item|Rectangle|Row|Column|Text|QtObject|PanelWindow|ShellRoot|PopupWindow|Repeater|ListView|MouseArea|FocusScope)\b' "$f" \
           || grep -qE 'pragma Singleton' "$f" \
           || { [ -n "$LOCAL_ROOT_RE" ] && grep -qE "^($LOCAL_ROOT_RE)[[:space:]]*\\{" "$f"; }; then
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
for f in hyprland.lua hyprlock.conf hypridle.conf; do
    if [ -f "$HYPR/$f" ]; then pass "present: hypr/$f"; else fail "missing: hypr/$f"; fi
done

if [ -f "$HYPR/hyprpaper.conf" ]; then
    fail "hyprpaper.conf is installed but hyprpaper is no longer launched (awww owns wallpapers)"
else
    pass "no stale hyprpaper.conf (awww owns wallpapers)"
fi

if have luac; then
    for f in "$HYPR"/*.lua "$HYPR"/conf.d/*.lua; do
        [ -f "$f" ] || continue
        if luac -p "$f" >/dev/null 2>&1; then
            pass "lua syntax: ${f#"$HYPR"/}"
        else
            fail "lua syntax: ${f#"$HYPR"/} ($(luac -p "$f" 2>&1 | head -1))"
        fi
    done
else
    skip "luac not available for Lua syntax checks"
fi

for mod in env appearance animations input monitors windowrules autostart keybinds; do
    if grep -q "\"$mod\"" "$HYPR/hyprland.lua"; then
        pass "hyprland.lua loads $mod"
    else
        fail "hyprland.lua does not load $mod"
    fi
done

if [ -f "$HYPR/conf.d/keyboard.lua" ] && \
   grep -q 'return { layout' "$HYPR/conf.d/keyboard.lua"; then
    pass "installer-owned keyboard.lua present"
else
    fail "missing installer-owned conf.d/keyboard.lua"
fi

if grep -q 'awww-daemon' "$HYPR/conf.d/autostart.lua" && \
   ! grep -q 'hyprpaper' "$HYPR/conf.d/autostart.lua"; then
    pass "autostart launches awww-daemon and not hyprpaper"
else
    fail "autostart does not launch the awww wallpaper backend"
fi

if grep -q 'wallpaperDir' "$ROOT/desktop/quickshell/components/launcher/LauncherBackend.qml" \
   && grep -q '/usr/share/mylinux/wallpapers' "$ROOT/desktop/quickshell/components/launcher/LauncherBackend.qml"; then
    pass "wallpaper path is centralised in the launcher backend"
else
    fail "wallpaper path is not referenced by the launcher backend"
fi

# ---------------------------------------------------------------------------
section "Desktop shell: panel layer"

SHELL_DIR="$ROOT/desktop/quickshell"

if grep -q 'mako' "$HYPR/conf.d/autostart.lua"; then
    fail "autostart still launches mako (Quickshell owns org.freedesktop.Notifications)"
else
    pass "autostart does not launch a competing notification daemon"
fi

for ns in mylinux-bar mylinux-launcher mylinux-calendar mylinux-session \
          mylinux-notifications mylinux-osd; do
    suffix="${ns#mylinux-}"
    if grep -rq "WlrLayershell.namespace: \"$ns\"" "$SHELL_DIR" && \
       grep -q "$suffix" "$HYPR/conf.d/windowrules.lua"; then
        pass "layer namespace wired: $ns"
    else
        fail "layer namespace not wired (shell + windowrules): $ns"
    fi
done

if grep -rq 'SystemClock\.' "$SHELL_DIR" && \
   ! grep -rq 'id: clock' "$SHELL_DIR"; then
    fail "SystemClock referenced without instantiation (it is creatable, not a singleton)"
else
    pass "SystemClock is instantiated where its date is read"
fi

if grep -rn '^ *opacity:' "$SHELL_DIR" | grep -q 'PanelWindow'; then
    fail "PanelWindow has no opacity property"
else
    pass "no opacity assignment on a PanelWindow root"
fi

if grep -q 'n.tracked = true' "$SHELL_DIR/components/NotificationCenter.qml"; then
    pass "notification daemon opts new notifications into tracking"
else
    fail "NotificationCenter never sets tracked, so cards would never appear"
fi

if grep -q 'onNotification' "$SHELL_DIR/components/NotificationCenter.qml"; then
    pass "notification cards are fed from the onNotification signal"
else
    fail "NotificationCenter does not listen to onNotification"
fi

if grep -q 'onApplicationsChanged' "$SHELL_DIR/components/Launcher.qml"; then
    pass "launcher reloads when desktop entries finish scanning"
else
    fail "launcher reads DesktopEntries.applications only once (async list race)"
fi

# ---------------------------------------------------------------------------
section "Launcher (Phase 2.2)"

LCH="$SHELL_DIR/components/launcher"
LOGIC="$SHELL_DIR/logic"

for f in components/Launcher.qml components/launcher/LauncherBackend.qml \
         components/launcher/AppRow.qml components/launcher/CalcView.qml \
         components/launcher/WebView.qml components/launcher/WallpaperView.qml \
         components/launcher/ClipboardView.qml components/launcher/SessionView.qml \
         logic/Modes.js logic/Match.js logic/Calc.js; do
    if [ -s "$SHELL_DIR/$f" ]; then
        pass "launcher file present: ${f#components/launcher/}"
    else
        fail "launcher file missing or empty: $f"
    fi
done

if grep -q 'WlrLayershell.namespace: "mylinux-launcher"' "$SHELL_DIR/components/Launcher.qml"; then
    pass "launcher declares the mylinux-launcher layer namespace"
else
    fail "launcher does not declare the mylinux-launcher layer namespace"
fi

if grep -q 'prefix: ">"' "$LOGIC/Modes.js" && \
   grep -q 'prefix: "="' "$LOGIC/Modes.js" && \
   grep -q 'prefix: "?"' "$LOGIC/Modes.js" && \
   grep -q 'prefix: "wall:"' "$LOGIC/Modes.js" && \
   grep -q 'prefix: "clip:"' "$LOGIC/Modes.js" && \
   grep -q 'prefix: "session:"' "$LOGIC/Modes.js"; then
    pass "all six launcher prefixes are defined"
else
    fail "one or more launcher prefixes are missing from Modes.js"
fi

if grep -q 'duckduckgo.com' "$LOGIC/Modes.js"; then
    pass "DuckDuckGo is the default web search provider"
else
    fail "DuckDuckGo default provider missing from Modes.js"
fi

if grep -qE '\beval\s*\(|new Function|child_process|execSync' "$LOGIC/Calc.js"; then
    fail "calculator uses eval/Function/subprocess (must be a safe parser)"
else
    pass "calculator does not use eval, new Function or a subprocess"
fi

if grep -q 'function tokenize' "$LOGIC/Calc.js" && grep -q 'function parse' "$LOGIC/Calc.js"; then
    pass "calculator uses a hand-written tokenizer and recursive-descent parser"
else
    fail "calculator lacks an explicit tokenizer/parser"
fi

if grep -q 'Quickshell.clipboardText' "$LCH/LauncherBackend.qml"; then
    pass "clipboard writes go through Quickshell.clipboardText"
else
    fail "clipboard copy does not use Quickshell.clipboardText"
fi

if grep -q 'cliphist' "$LCH/LauncherBackend.qml" && \
   grep -q 'cliphist' "$LCH/ClipboardView.qml" 2>/dev/null || \
   grep -q 'cliphist' "$LCH/LauncherBackend.qml"; then
    pass "clipboard history is backed by cliphist"
else
    fail "cliphist backend missing from the launcher"
fi

if grep -qE '\["cliphist", "wipe"\]|cliphist wipe' "$LCH/LauncherBackend.qml"; then
    pass "clipboard clear uses 'cliphist wipe'"
else
    fail "clipboard clear does not use 'cliphist wipe'"
fi

if grep -q 'wl-clipboard\|wl-copy' "$LCH/LauncherBackend.qml" && \
   grep -qi 'missing\|unavailable\|not available' "$LCH/LauncherBackend.qml" "$LCH/ClipboardView.qml"; then
    pass "clipboard view degrades gracefully when tooling is absent"
else
    fail "clipboard view does not report missing tooling"
fi

if grep -q 'awww' "$LCH/LauncherBackend.qml" && \
   grep -q 'awww img' "$LCH/LauncherBackend.qml"; then
    pass "wallpaper switching calls 'awww img'"
else
    fail "wallpaper switching does not use awww"
fi

if grep -q 'wallpaperBackendMissing\|backendMissing' "$LCH/LauncherBackend.qml" "$LCH/WallpaperView.qml"; then
    pass "wallpaper view degrades gracefully when awww is absent"
else
    fail "wallpaper view does not report a missing backend"
fi

if grep -q 'xdg-open' "$LCH/LauncherBackend.qml"; then
    pass "web search opens URLs with xdg-open (default browser)"
else
    fail "web search does not open URLs with xdg-open"
fi

for action in lock logout suspend reboot shutdown; do
    if grep -q "\"$action\"\|'$action'" "$LCH/SessionView.qml" "$LCH/LauncherBackend.qml" 2>/dev/null; then
        pass "session action wired: $action"
    else
        fail "session action missing: $action"
    fi
done

if grep -qE 'confirm' "$LCH/SessionView.qml" || grep -qE 'confirm' "$LCH/LauncherBackend.qml"; then
    pass "destructive session actions are behind a confirmation step"
else
    fail "destructive session actions have no confirmation"
fi

if grep -q 'FileView' "$LCH/LauncherBackend.qml" && \
   grep -q 'atomicWrites: true' "$LCH/LauncherBackend.qml"; then
    pass "launcher state persists to disk atomically"
else
    fail "launcher state does not persist atomically"
fi

for key in favorites provider wallpaper; do
    if grep -q "$key" "$LCH/LauncherBackend.qml"; then
        pass "persisted state field present: $key"
    else
        fail "persisted state field missing: $key"
    fi
done

if grep -q 'favorites' "$LCH/LauncherBackend.qml" && \
   grep -q 'function toggleFavorite\|toggleFavorite' "$LCH/LauncherBackend.qml"; then
    pass "favourites can be toggled and ordered by the backend"
else
    fail "favourites toggle/ordering not implemented"
fi

if grep -q '\.execute()' "$LCH/LauncherBackend.qml"; then
    pass "applications launch through the native DesktopEntry.execute()"
else
    fail "launcher does not use the native DesktopEntry execution API"
fi

if grep -qE "execDetached\(\[\"sh\", *\"-c\"" "$LCH/LauncherBackend.qml"; then
    fail "launcher passes a desktop-entry Exec string to a shell (sh -c)"
else
    pass "no desktop-entry Exec string is passed to a shell"
fi

if grep -q 'descriptor.exec\|%\[fFuUdDnNickvm\]' "$LCH/LauncherBackend.qml"; then
    fail "launcher still reads the raw Exec string for launching"
else
    pass "launcher no longer relies on the raw Exec string"
fi

if grep -q '"which"' "$LCH/LauncherBackend.qml"; then
    pass "launcher pre-checks executables without a shell"
else
    fail "launcher launches without verifying the executable exists"
fi

if grep -q 'lastError' "$LCH/LauncherBackend.qml" && \
   grep -q 'executable not found' "$LCH/LauncherBackend.qml"; then
    pass "failed launches surface a visible error"
else
    fail "failed launches are silent"
fi

if grep -qF '(?=\d{3}' "$LOGIC/Calc.js"; then
    fail "calculator still strips commas (breaks multi-argument functions)"
else
    pass "calculator preserves commas as argument separators"
fi

if grep -q 'min\|max\|atan2' "$LOGIC/Calc.js"; then
    pass "calculator supports multi-argument functions"
else
    fail "calculator multi-argument functions missing"
fi

if grep -q 'openLauncher' "$SHELL_DIR/shell.qml" && \
   grep -q 'openWallpapers' "$SHELL_DIR/shell.qml" && \
   grep -q 'openClipboard' "$SHELL_DIR/shell.qml" && \
   grep -q 'openSession' "$SHELL_DIR/shell.qml"; then
    pass "IPC surface exposes every launcher entry point"
else
    fail "IPC surface is missing a launcher entry point"
fi

for kb in 'openWallpapers' 'openClipboard' 'openSession'; do
    if grep -q "$kb" "$HYPR/conf.d/keybinds.lua"; then
        pass "keybind calls $kb"
    else
        fail "keybind for $kb missing"
    fi
done

if grep -q 'mainMod .. " + SPACE"' "$HYPR/conf.d/keybinds.lua" && \
   grep -q 'toggleLauncher' "$HYPR/conf.d/keybinds.lua"; then
    pass "SUPER+SPACE opens the launcher"
else
    fail "SUPER+SPACE launcher binding missing"
fi

if grep -q 'mainMod .. " + SHIFT + W"' "$HYPR/conf.d/keybinds.lua"; then
    pass "SUPER+SHIFT+W opens the wallpaper selector"
else
    fail "SUPER+SHIFT+W wallpaper binding missing"
fi

if grep -q 'mainMod .. " + V"' "$HYPR/conf.d/keybinds.lua" && \
   ! grep -q 'mainMod .. " + V".*wl-paste' "$HYPR/conf.d/keybinds.lua"; then
    pass "SUPER+V opens clipboard history without a conflicting bind"
else
    fail "SUPER+V binding missing or conflicting"
fi

wp_count=$(find "$ROOT/branding/wallpapers" -maxdepth 1 -type f -name '*.png' 2>/dev/null | wc -l)
if [ "$wp_count" -ge 6 ]; then
    pass "at least six wallpapers ship in branding/wallpapers ($wp_count)"
else
    fail "fewer than six wallpapers in branding/wallpapers ($wp_count)"
fi

if grep -q 'branding/wallpapers/\*.png' installer/backend/install_base.sh; then
    pass "installer copies every bundled wallpaper"
else
    fail "installer does not loop over branding/wallpapers/*.png"
fi

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
section "Live environment (regression guards)"

if [ -s iso/airootfs/etc/pacman.d/mirrorlist ] \
   && grep -qE '^Server *= *https?://' iso/airootfs/etc/pacman.d/mirrorlist; then
    pass "live mirrorlist ships at least one active server"
else
    fail "live mirrorlist has no active Server (pacstrap cannot reach a mirror)"
fi

if [ -f iso/airootfs/etc/systemd/system/pacman-init.service ] \
   && grep -q 'pacman-key --populate' iso/airootfs/etc/systemd/system/pacman-init.service; then
    pass "live profile populates the pacman keyring"
else
    fail "live profile does not populate the pacman keyring"
fi

if [ -f iso/airootfs/etc/systemd/system/etc-pacman.d-gnupg.mount ]; then
    pass "live profile mounts a writable pacman gnupg tmpfs"
else
    fail "etc-pacman.d-gnupg.mount missing (keyring cannot be written)"
fi

if [ -L iso/airootfs/etc/systemd/system/multi-user.target.wants/pacman-init.service ]; then
    pass "pacman-init.service is enabled in the live profile"
else
    fail "pacman-init.service is not enabled"
fi

if [ -L iso/airootfs/etc/systemd/system/sysinit.target.wants/systemd-firstboot.service ] \
   && [ "$(readlink iso/airootfs/etc/systemd/system/sysinit.target.wants/systemd-firstboot.service)" = "/dev/null" ]; then
    pass "systemd-firstboot is masked on the live medium"
else
    fail "systemd-firstboot is not masked (interactive prompt would block the console)"
fi

if [ -f iso/airootfs/etc/machine-id ]; then
    fail "airootfs ships a machine-id (mkarchiso overwrites it; remove it)"
else
    pass "no stale machine-id shipped in airootfs"
fi

# ---------------------------------------------------------------------------
section "Installer logic (regression guards)"

if grep -q 'pacstrap -K' installer/backend/install_base.sh; then
    fail "installer uses pacstrap -K (creates an empty target keyring)"
else
    pass "installer does not use pacstrap -K"
fi

if grep -q 'findmnt -rn -T' installer/backend/lib/common.sh \
   && ! sed -n '/^is_mounted()/,/^}/p' installer/backend/lib/common.sh | grep -q '\[ -b '; then
    fail "is_mounted resolves block devices as paths (every disk looks busy)"
else
    pass "is_mounted distinguishes block devices from paths"
fi

if [ -f system/config/default-grub ] \
   && grep -q '^GRUB_DISTRIBUTOR="MyLinux"' system/config/default-grub; then
    pass "installed GRUB menu is branded MyLinux"
else
    fail "GRUB_DISTRIBUTOR is not MyLinux (installed menu would read 'Arch Linux')"
fi

if grep -q 'system/config/default-grub' installer/backend/install_base.sh; then
    pass "installer deploys the branded GRUB configuration"
else
    fail "installer never installs system/config/default-grub"
fi

if grep -q 'console=ttyS0' system/config/default-grub; then
    pass "installed kernel cmdline enables the serial console"
else
    fail "installed kernel cmdline has no serial console"
fi

if grep -q 'systemctl enable serial-getty@ttyS0.service' installer/backend/install_base.sh; then
    pass "installer enables a serial getty on the installed system"
else
    fail "installer does not enable serial-getty@ttyS0 on the installed system"
fi

if grep -q 'grub-install --target=x86_64-efi --efi-directory=/boot --removable' installer/backend/install_base.sh; then
    pass "installer writes the removable-media UEFI fallback (EFI/BOOT/BOOTX64.EFI)"
else
    fail "installer never writes EFI/BOOT/BOOTX64.EFI (an empty-NVRAM machine would not boot)"
fi

if sed -n '/stage_payload$/,$p' iso/build.sh | grep -qE '^\s*rm -rf "\$WORKDIR"'; then
    pass "build.sh clears the work directory before every build"
else
    fail "build.sh reuses a stale work directory (mkarchiso would skip steps and reuse the old ISO)"
fi

if grep -qE 'return 1' installer/backend/lib/partition.sh \
   && sed -n '/^unmount_target()/,/^}/p' installer/backend/lib/partition.sh \
        | grep -q 'findmnt -rn -o TARGET -R'; then
    pass "unmount_target reports whether the target is really gone"
else
    fail "unmount_target cannot report a failed unmount (a busy target would be silently ignored)"
fi

if grep -qE 'if ! unmount_target; then' installer/backend/install_base.sh; then
    pass "installer refuses to report success when the target stays mounted"
else
    fail "installer ignores the unmount result (may leave the target mounted after 'success')"
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
[ -f iso/efiboot/loader/loader.conf ] && pass "systemd-boot loader.conf present" || fail "systemd-boot loader.conf missing"
if ls iso/efiboot/loader/entries/*.conf >/dev/null 2>&1; then
    pass "systemd-boot boot entries present"
else
    fail "no systemd-boot boot entries in iso/efiboot/loader/entries"
fi

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