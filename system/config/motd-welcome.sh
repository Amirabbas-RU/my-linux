# MyLinux — login greeting.
#
# Shown on a TTY at login. The desktop session has its own bar and launcher, so
# this only greets the user and points at the essentials.

if [ -z "${MYLINUX_GREETED:-}" ] && [ -t 1 ]; then
    export MYLINUX_GREETED=1
    printf '\n  \033[1mMyLinux\033[0m %s  (%s)\n' \
        "$(uname -r)" "${XDG_CURRENT_DESKTOP:-console}"
    printf '  Update:  \033[1msudo mylinux-update\033[0m     Docs: \033[1m/usr/share/doc/mylinux/\033[0m\n'
    printf '  Details: \033[1mmylinux-systeminfo\033[0m\n\n'
fi