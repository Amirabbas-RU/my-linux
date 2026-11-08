// MyLinux Quickshell entry point.
//
// Quickshell loads this file and instantiates every child. Each top-level
// object owns one surface of the desktop: the bar, the launcher, the
// notification daemon, the OSD, the power menu and the calendar.
import QtQuick
import Quickshell
import Quickshell.Io

import "theme"
import "components"

ShellRoot {
    id: root

    // Central shell state shared across components.
    ShellState { id: state }

    // Top panel.
    Bar {
        id: bar
        shellState: state
    }

    // Application launcher overlay.
    Launcher {
        id: launcher
        shellState: state
    }

    // Volume / brightness on-screen display.
    Osd {
        id: osd
        shellState: state
    }

    // Notification daemon + popups.
    NotificationCenter {
        id: notifications
        shellState: state
    }

    // Lock / logout / reboot / shutdown interface.
    PowerMenu {
        id: powerMenu
        shellState: state
    }

    // Clock calendar popup.
    CalendarPopup {
        id: calendar
        shellState: state
    }

    // IPC surface so keybinds and scripts can drive the shell.
    IpcHandler {
        target: "mylinux"
        function toggleLauncher(): void { state.launcherOpen = !state.launcherOpen }
        function toggleCalendar(): void { state.calendarOpen = !state.calendarOpen }
        function togglePowerMenu(): void { state.powerMenuOpen = !state.powerMenuOpen }
        function showOsd(): void { osd.ping() }
    }
}
