import QtQuick
import Quickshell
import Quickshell.Io

import "theme"
import "components"
import "components/launcher"

ShellRoot {
    id: root

    ShellState { id: state }

    ThemeStore { id: themeStore }

    LauncherBackend { id: launcherBackend }

    Bar {
        id: bar
        shellState: state
    }

    Launcher {
        id: launcher
        shellState: state
        backend: launcherBackend
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

    NetworkPopup {
        id: network
        shellState: state
    }

    VolumePopup {
        id: volume
        shellState: state
    }

    PowerMenu {
        id: powerMenu
        shellState: state
    }

    SettingsWindow {
        id: settings
        shellState: state
        backend: launcherBackend
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
        function toggleSettings(): void { state.toggleSettings() }
        function openSettings(page: string): void { state.openSettings(page) }
        function toggleNetwork(): void { state.toggleNetwork() }
        function toggleVolume(): void { state.toggleVolume() }
        function clearNotifications(): void { notifications.clearAll() }
        function closeAll(): void { state.closeAll() }
        function showVolume(): void { osd.showVolume() }
        function reload(): void { Quickshell.reload(false) }
    }
}