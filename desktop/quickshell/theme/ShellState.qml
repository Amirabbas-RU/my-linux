import QtQuick
import Quickshell

QtObject {
    id: state

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool calendarOpen: false
    property bool powerMenuOpen: false
    property bool notificationCenterOpen: false

    property bool reducedMotion: false
    property bool panelVisible: true

    property int batteryPercent: -1
    property bool batteryCharging: false
    property bool batteryPresent: false

    property string wifiSsid: ""
    property bool wifiEnabled: false
    property bool wiredConnected: false
    property bool bluetoothEnabled: false
    property bool bluetoothAvailable: false

    property real volume: 0.0
    property bool muted: false

    property bool dnd: false
    property int notificationCount: 0

    property string wallpaper: "/usr/share/mylinux/wallpapers/mylinux-default.png"

    function closeAll(): void {
        launcherOpen = false
        controlCenterOpen = false
        calendarOpen = false
        powerMenuOpen = false
        notificationCenterOpen = false
    }

    function toggleLauncher(): void {
        const open = !launcherOpen
        closeAll()
        launcherOpen = open
    }

    function toggleControlCenter(): void {
        const open = !controlCenterOpen
        closeAll()
        controlCenterOpen = open
    }

    function toggleCalendar(): void {
        const open = !calendarOpen
        closeAll()
        calendarOpen = open
    }

    function togglePowerMenu(): void {
        const open = !powerMenuOpen
        closeAll()
        powerMenuOpen = open
    }
}