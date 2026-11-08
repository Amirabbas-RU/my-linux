#!/usr/bin/env bash
# MyLinux installer — backend orchestrator.
#
# Performs a full unattended-or-guided install of MyLinux onto a target disk.
# The interactive frontend (installer/frontend/mylinux-install) collects answers,
# writes a configuration file, and then invokes this script with --config.
#
# Usage:
#   install_base.sh --config /path/to/answers.conf [--dry-run]
#   install_base.sh --interactive
#
# The configuration file is a shell fragment defining the variables documented
# in installer/CONFIG.md. This script validates every value before touching the
# disk; nothing destructive happens until the disk-safety checks pass.

set -Eeuo pipefail

# Resolve our own directory so the libs and source tree are found regardless of
# where the installer is invoked from.
MYLINUX_INSTALLER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MYLINUX_INSTALLER_ROOT="$(cd -- "$MYLINUX_INSTALLER_DIR/.." && pwd)"

# shellcheck source=lib/common.sh
. "$MYLINUX_INSTALLER_DIR/lib/common.sh"
# shellcheck source=lib/disk.sh
. "$MYLINUX_INSTALLER_DIR/lib/disk.sh"
# shellcheck source=lib/partition.sh
. "$MYLINUX_INSTALLER_DIR/lib/partition.sh"

usage() {
    cat <<EOF
MyLinux installer backend

  install_base.sh --config FILE     run with a pre-filled answer file
  install_base.sh --interactive     simple prompt-driven install
  install_base.sh --check           validate environment and answer file only
  install_base.sh --dry-run         validate + plan without touching disks
  install_base.sh --help

Environment:
  MYLINUX_SOURCE   source tree (default: /usr/share/mylinux)
  MYLINUX_TARGET   mountpoint for the new system (default: /mnt/mylinux-target)
EOF
}

# ---- defaults ------------------------------------------------------------
TARGET_DISK=""
ROOT_FS="ext4"
HOSTNAME="mylinux"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"
KEYMAP="us"
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
INSTALL_DESKTOP="yes"
BOOTLOADER="grub"          # grub | systemd-boot
KERNEL="linux"
ESP_SIZE_MIB="512"
WIPE_MODE="whole"          # whole | quick
CONFIG_FILE=""
MODE="config"
DRY_RUN="no"

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --config)      CONFIG_FILE="$2"; MODE="config"; shift 2 ;;
            --interactive) MODE="interactive"; shift ;;
            --check)       MODE="check"; shift ;;
            --dry-run)     DRY_RUN="yes"; shift ;;
            --target)      TARGET_DISK="$2"; shift 2 ;;
            -h|--help)     usage; exit 0 ;;
            *)             die "unknown argument: $1" ;;
        esac
    done
}

# ---- validation ----------------------------------------------------------
validate_config() {
    step "Validating installation configuration"

    [ -n "$TARGET_DISK" ] || die "no target disk configured (TARGET_DISK)"
    assert_selectable "$TARGET_DISK"

    case "$ROOT_FS" in ext4|btrfs|xfs) ;; *) die "unsupported ROOT_FS: $ROOT_FS" ;; esac
    case "$BOOTLOADER" in grub|systemd-boot) ;; *) die "unsupported BOOTLOADER: $BOOTLOADER" ;; esac
    case "$INSTALL_DESKTOP" in yes|no) ;; *) die "INSTALL_DESKTOP must be yes or no" ;; esac

    [ -n "$HOSTNAME" ] || die "HOSTNAME must not be empty"
    printf '%s' "$HOSTNAME" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9-]*$' \
        || die "HOSTNAME '$HOSTNAME' is not a valid hostname"

    [ -f "/usr/share/zoneinfo/$TIMEZONE" ] || die "unknown TIMEZONE: $TIMEZONE"
    [ -n "$USERNAME" ] || die "USERNAME must not be empty (refusing to create a system with no login)"
    printf '%s' "$USERNAME" | grep -qE '^[a-z_][a-z0-9_-]*$' \
        || die "USERNAME '$USERNAME' is not a valid Linux username"

    [ -n "$USER_PASSWORD" ] || die "USER_PASSWORD must be set"
    [ -n "$ROOT_PASSWORD" ] || die "ROOT_PASSWORD must be set"

    require_source
    for f in packages/base.txt packages/desktop.txt; do
        [ -f "$MYLINUX_SOURCE/$f" ] || die "missing package list: $MYLINUX_SOURCE/$f"
    done

    info "configuration validated for target $TARGET_DISK ($ROOT_FS, $BOOTLOADER, desktop=$INSTALL_DESKTOP)"
}

# ---- package selection ---------------------------------------------------
package_list() {
    local list="$MYLINUX_SOURCE/packages/base.txt"
    grep -vE '^\s*(#|$)' "$list"
    if [ "$INSTALL_DESKTOP" = "yes" ]; then
        grep -vE '^\s*(#|$)' "$MYLINUX_SOURCE/packages/desktop.txt"
    fi
    # Kernel choice
    printf '%s\n' "$KERNEL"
    if [ "$KERNEL" = "linux" ]; then
        printf '%s\n' "linux-headers"
    fi
}

# ---- stage: filesystem ---------------------------------------------------
stage_partition() {
    step "Partitioning $TARGET_DISK"
    if [ "$DRY_RUN" = "yes" ]; then
        info "[dry-run] would wipe ($WIPE_MODE) and partition $TARGET_DISK"
        return 0
    fi
    assert_selectable "$TARGET_DISK"
    wipe_disk "$TARGET_DISK" "$WIPE_MODE"
    local layout; layout="$(create_partitions "$TARGET_DISK" "$ESP_SIZE_MIB")"
    ESP_DEV="$(printf '%s\n' "$layout" | sed -n '1p')"
    ROOT_DEV="$(printf '%s\n' "$layout" | sed -n '2p')"
    info "layout: ESP=$ESP_DEV ROOT=$ROOT_DEV"
}

stage_format() {
    step "Formatting filesystems"
    [ -n "${ESP_DEV:-}" ] && [ -n "${ROOT_DEV:-}" ] || die "partition stage did not run"
    if [ "$DRY_RUN" = "yes" ]; then
        info "[dry-run] would format $ESP_DEV (FAT32) and $ROOT_DEV ($ROOT_FS)"
        return 0
    fi
    format_filesystems "$ESP_DEV" "$ROOT_DEV" "$ROOT_FS"
    mount_target "$ESP_DEV" "$ROOT_DEV" "$ROOT_FS"
}

# ---- stage: base system --------------------------------------------------
stage_base() {
    step "Installing base system with pacstrap"
    if [ "$DRY_RUN" = "yes" ]; then
        info "[dry-run] would pacstrap this package set:"
        package_list | sed 's/^/    /'
        return 0
    fi

    # Mirror selection: prefer the live environment's mirrorlist, but ensure the
    # target has one even if the live image shipped a stub.
    install -Dm644 /etc/pacman.d/mirrorlist "$MYLINUX_TARGET/etc/pacman.d/mirrorlist"

    local pkgs; pkgs="$(package_list | tr '\n' ' ')"
    # shellcheck disable=SC2086
    run "pacstrap base + MyLinux package set" pacstrap -K "$MYLINUX_TARGET" $pkgs

    # Keep the installer's own copy of the mirrorlist in case pacstrap replaced it.
    install -Dm644 /etc/pacman.d/mirrorlist "$MYLINUX_TARGET/etc/pacman.d/mirrorlist"
}

write_fstab() {
    step "Generating /etc/fstab"
    [ "$DRY_RUN" = "yes" ] && { info "[dry-run] would write fstab"; return 0; }
    run "generating fstab" bash -c "genfstab -U '$MYLINUX_TARGET' >> '$MYLINUX_TARGET/etc/fstab'"
}

# chroot helper — runs a shell snippet inside the new system with our source
# tree and variables exported.
in_target() {
    arch-chroot "$MYLINUX_TARGET" /bin/bash -c "$1"
}

stage_configure() {
    step "Configuring base system"
    [ "$DRY_RUN" = "yes" ] && { info "[dry-run] would configure locale/timezone/users/bootloader"; return 0; }

    # --- timezone ---------------------------------------------------------
    run "setting timezone" bash -c \
        "ln -sf /usr/share/zoneinfo/'$TIMEZONE' '$MYLINUX_TARGET/etc/localtime'"
    in_target "hwclock --systohc"

    # --- locale -----------------------------------------------------------
    info "enabling locale $LOCALE"
    bash -c "printf '%s UTF-8\n' '$LOCALE' >> '$MYLINUX_TARGET/etc/locale.gen'"
    in_target "locale-gen"
    bash -c "printf 'LANG=%s\n' '$LOCALE' > '$MYLINUX_TARGET/etc/locale.conf'"

    # --- console keymap ---------------------------------------------------
    bash -c "printf 'KEYMAP=%s\nFONT=ter-124b\n' '$KEYMAP' > '$MYLINUX_TARGET/etc/vconsole.conf'"

    # --- hostname ---------------------------------------------------------
    bash -c "printf '%s\n' '$HOSTNAME' > '$MYLINUX_TARGET/etc/hostname'"
    bash -c "printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t%s.localdomain\t%s\n' \
             '$HOSTNAME' '$HOSTNAME' > '$MYLINUX_TARGET/etc/hosts'"

    # --- users ------------------------------------------------------------
    info "creating user $USERNAME"
    in_target "useradd -m -G wheel,video,audio,input,render -s /bin/bash '$USERNAME'"
    in_target "printf '%s:%s\n' root '$ROOT_PASSWORD' | chpasswd"
    in_target "printf '%s:%s\n' '$USERNAME' '$USER_PASSWORD' | chpasswd"

    # wheel sudoers
    bash -c "printf '%%wheel ALL=(ALL:ALL) ALL\n' > '$MYLINUX_TARGET/etc/sudoers.d/10-mylinux-wheel'"
    bash -c "chmod 440 '$MYLINUX_TARGET/etc/sudoers.d/10-mylinux-wheel'"

    # --- os-release / branding -------------------------------------------
    install -Dm644 "$MYLINUX_SOURCE/branding/os-release" "$MYLINUX_TARGET/etc/os-release"
    install -Dm644 "$MYLINUX_SOURCE/branding/logo/mylinux-logo.txt" "$MYLINUX_TARGET/etc/issue"
    install -Dm644 "$MYLINUX_SOURCE/branding/logo/mylinux-logo.svg" "$MYLINUX_TARGET/usr/share/mylinux/logo/mylinux-logo.svg"
    install -Dm644 "$MYLINUX_SOURCE/branding/wallpapers/mylinux-default.png" \
        "$MYLINUX_TARGET/usr/share/mylinux/wallpapers/mylinux-default.png"

    # --- mkinitcpio -------------------------------------------------------
    install -Dm644 "$MYLINUX_SOURCE/system/config/mkinitcpio.conf" "$MYLINUX_TARGET/etc/mkinitcpio.conf"
    in_target "mkinitcpio -P"

    # --- services ---------------------------------------------------------
    info "enabling system services"
    in_target "systemctl enable NetworkManager"
    in_target "systemctl enable bluetooth"
    in_target "systemctl enable systemd-timesyncd"
    [ "$INSTALL_DESKTOP" = "yes" ] && in_target "systemctl enable sddm"

    # journald + timesyncd tuning from the repo
    install -Dm644 "$MYLINUX_SOURCE/system/services/journald.conf" "$MYLINUX_TARGET/etc/systemd/journald.conf.d/10-mylinux.conf"
    install -Dm644 "$MYLINUX_SOURCE/system/services/timesyncd.conf" "$MYLINUX_TARGET/etc/systemd/timesyncd.conf.d/10-mylinux.conf"

    # --- MyLinux helpers --------------------------------------------------
    for s in mylinux-systeminfo mylinux-update mylinux-welcome; do
        install -Dm755 "$MYLINUX_SOURCE/system/scripts/$s" "$MYLINUX_TARGET/usr/local/bin/$s"
    done
    install -Dm644 "$MYLINUX_SOURCE/system/services/mylinux-firstboot.service" \
        "$MYLINUX_TARGET/usr/lib/systemd/system/mylinux-firstboot.service"
    in_target "systemctl enable mylinux-firstboot.service"

    # --- docs -------------------------------------------------------------
    install -d "$MYLINUX_TARGET/usr/share/doc/mylinux"
    cp -a "$MYLINUX_SOURCE/docs/." "$MYLINUX_TARGET/usr/share/doc/mylinux/" 2>/dev/null || true
}

stage_desktop() {
    [ "$INSTALL_DESKTOP" = "yes" ] || { info "desktop install disabled; skipping desktop configuration"; return 0; }
    step "Configuring Hyprland + Quickshell desktop"
    [ "$DRY_RUN" = "yes" ] && { info "[dry-run] would install desktop configs for $USERNAME"; return 0; }

    local home="$MYLINUX_TARGET/home/$USERNAME"

    # Per-user configuration. Installed under /etc/skel so new users inherit it,
    # and copied into the freshly created user's home.
    run "installing Hyprland configuration" cp -a "$MYLINUX_SOURCE/desktop/hypr" "$MYLINUX_TARGET/etc/skel/.config/hypr"
    run "installing Quickshell configuration" cp -a "$MYLINUX_SOURCE/desktop/quickshell" "$MYLINUX_TARGET/etc/skel/.config/quickshell"

    run "installing desktop config for $USERNAME" cp -a "$MYLINUX_TARGET/etc/skel/.config" "$home/"

    # Keyboard layout chosen at install time is reflected in the Hyprland input
    # config so the desktop matches the console keymap.
    sed -i "s/^\(\s*kb_layout\s*=\s*\).*/\1$KEYMAP/" "$home/.config/hypr/conf.d/input.conf"

    # SDDM: select the Hyprland session by default and theme it minimally.
    install -d "$MYLINUX_TARGET/etc/sddm.conf.d"
    cat > "$MYLINUX_TARGET/etc/sddm.conf.d/10-mylinux.conf" <<EOF
[Autologin]
User=
[Theme]
Current=mylinux
[Users]
MaximumUid=60000
MinimumUid=1000
EOF

    # Own the user's configuration.
    in_target "chown -R '$USERNAME:$USERNAME' '/home/$USERNAME'"

    # Desktop shell as a user service (optional; Hyprland autostart also runs it).
    install -Dm644 "$MYLINUX_SOURCE/system/services/mylinux-shell.service" \
        "$MYLINUX_TARGET/usr/lib/systemd/user/mylinux-shell.service"
}

stage_bootloader() {
    step "Installing bootloader ($BOOTLOADER)"
    [ "$DRY_RUN" = "yes" ] && { info "[dry-run] would install $BOOTLOADER"; return 0; }

    case "$BOOTLOADER" in
        grub)
            in_target "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=MyLinux --recheck"
            in_target "grub-mkconfig -o /boot/grub/grub.cfg" ;;
        systemd-boot)
            in_target "bootctl --esp-path=/boot install"
            local root_uuid; root_uuid="$(blkid -s UUID -o value "$ROOT_DEV")"
            local cmdline="root=UUID=$root_uuid rw rootfstype=$ROOT_FS"
            [ "$ROOT_FS" = "btrfs" ] && cmdline="$cmdline rootflags=subvol=@"
            install -d "$MYLINUX_TARGET/boot/loader/entries"
            cat > "$MYLINUX_TARGET/boot/loader/entries/mylinux.conf" <<EOF
title   MyLinux
linux   /vmlinuz-$KERNEL
initrd  /initramfs-$KERNEL.img
options $cmdline
EOF
            cat > "$MYLINUX_TARGET/boot/loader/loader.conf" <<EOF
default mylinux.conf
timeout 4
editor  no
EOF
            ;;
    esac
}

# ---- full run ------------------------------------------------------------
run_install() {
    step "Starting MyLinux installation"
    info "target=$TARGET_DISK fs=$ROOT_FS bootloader=$BOOTLOADER desktop=$INSTALL_DESKTOP user=$USERNAME"

    if [ "$DRY_RUN" != "yes" ]; then
        # The single human gate. Never bypassed by the frontend.
        if ! confirm_destructive "$TARGET_DISK"; then
            die "installation aborted by user at the destructive-operation prompt"
        fi
        # Re-assert after confirmation in case anything changed under us.
        assert_selectable "$TARGET_DISK"
    fi

    stage_partition
    stage_format
    stage_base
    write_fstab
    stage_configure
    stage_desktop
    stage_bootloader

    if [ "$DRY_RUN" != "yes" ]; then
        step "Syncing and unmounting"
        sync
        unmount_target
    fi

    step "Installation complete"
    printf '\n%sMyLinux has been installed to %s.%s\n' "$C_GREEN" "$TARGET_DISK" "$C_RESET"
    printf 'You can now reboot and remove the installation medium.\n'
}

# ---- interactive mode ----------------------------------------------------
interactive() {
    require_root; require_uefi
    step "MyLinux interactive installer"

    # Disk selection
    echo "Available disks:"
    local i=1
    mapfile -t DISKS < <(list_install_disks)
    for d in "${DISKS[@]}"; do
        IFS='|' read -r dev bytes model tran rm <<<"$d"
        local note=""
        is_protected "$dev" && note="  <-- PROTECTED (running system / live medium)"
        printf '  %d) %-12s %-8s %-6s %s%s\n' "$i" "$dev" "$(human_size "$bytes")" "$tran" "$model" "$note"
        i=$((i+1))
    done
    printf 'Select target disk number: '
    read -r choice
    [ -n "${DISKS[$((choice-1))]:-}" ] || die "invalid selection"
    TARGET_DISK="$(printf '%s' "${DISKS[$((choice-1))]}" | cut -d'|' -f1)"

    printf 'Root filesystem [ext4/btrfs/xfs] (ext4): '; read -r v; [ -n "$v" ] && ROOT_FS="$v"
    printf 'Bootloader [grub/systemd-boot] (grub): ';   read -r v; [ -n "$v" ] && BOOTLOADER="$v"
    printf 'Hostname (mylinux): ';                      read -r v; [ -n "$v" ] && HOSTNAME="$v"
    printf 'Timezone (UTC, e.g. Europe/Berlin): ';      read -r v; [ -n "$v" ] && TIMEZONE="$v"
    printf 'Locale (en_US.UTF-8): ';                    read -r v; [ -n "$v" ] && LOCALE="$v"
    printf 'Console keymap (us): ';                     read -r v; [ -n "$v" ] && KEYMAP="$v"
    printf 'Username: ';                                read -r USERNAME
    printf 'User password: ';                           read -rs USER_PASSWORD; echo
    printf 'Root password: ';                           read -rs ROOT_PASSWORD; echo
    printf 'Install desktop (yes/no) (yes): ';          read -r v; [ -n "$v" ] && INSTALL_DESKTOP="$v"

    validate_config
    run_install
}

main() {
    parse_args "$@"
    require_root

    case "$MODE" in
        config)
            [ -n "$CONFIG_FILE" ] || die "--config requires a file path"
            [ -r "$CONFIG_FILE" ] || die "cannot read config: $CONFIG_FILE"
            info "loading configuration from $CONFIG_FILE"
            # shellcheck disable=SC1090
            . "$CONFIG_FILE"
            validate_config
            run_install ;;
        interactive)
            interactive ;;
        check)
            [ -n "$CONFIG_FILE" ] && { . "$CONFIG_FILE"; }
            validate_config
            info "environment check passed" ;;
    esac
}

main "$@"
