import QtQuick
import Quickshell
import Quickshell.Io

import "theme"
import "components"

ShellRoot {
    id: root

    ShellState { id: state }

    Bar {
        id: bar
        shellState: state
    }

    Launcher {
        id: launcher
        shellState: state
    }

    NotificationCenter {
        id: notifications
        shellState: state
    }

    Osd {
        id: osd
        shellState: state
    }

    CalendarPopup {
        id: calendar
        shellState: state
    }

    PowerMenu {
        id: powerMenu
        shellState: state
    }

    IpcHandler {
        target: "mylinux"

        function toggleLauncher(): void { state.toggleLauncher() }
        function openLauncher(mode: string): void { state.openLauncher(mode) }
        function openLauncherWith(mode: string, query: string): void { state.openLauncher(mode, query) }
        function openWallpapers(): void { state.openLauncher("wall") }
        function openClipboard(): void { state.openLauncher("clip") }
        function openSession(): void { state.openLauncher("session") }
        function toggleCalendar(): void { state.toggleCalendar() }
        function togglePowerMenu(): void { state.togglePowerMenu() }
        function toggleNotifications(): void { state.notificationCenterOpen = !state.notificationCenterOpen }
        function clearNotifications(): void { notifications.clearAll() }
        function closeAll(): void { state.closeAll() }
        function showVolume(): void { osd.showVolume() }
        function reload(): void { Quickshell.reload(false) }
    }
}