# MyLinux live shell profile — starts the welcome screen on the first console.
# Guarded so non-interactive shells (scripts, scp) are unaffected.

if [ -z "$MYLINUX_LIVE_WELCOME_SHOWN" ] && [ -t 0 ] && [ "$(id -u)" -eq 0 ]; then
    case "$(tty)" in
        /dev/tty1) export MYLINUX_LIVE_WELCOME_SHOWN=1; /usr/local/bin/mylinux-live-welcome ;;
    esac
fi
