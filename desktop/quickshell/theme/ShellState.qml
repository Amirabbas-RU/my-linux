import QtQuick
import Quickshell

// ShellState holds global, mutable desktop state so individual surfaces can
// observe and mutate it without depending on each other. Keeping this central
// avoids hardcoding state inside panels and makes the shell testable.
QtObject {
    id: state

    // Which surfaces are open.
    property bool launcherOpen: false
    property bool calendarOpen: false
    property bool powerMenuOpen: false
    property bool notificationOpen: false

    // Live system values populated by the bar's polling services.
    property string clock: ""
    property string date: ""
    property int volume: 0
    property bool muted: false
    property int brightness: 0
    property string wifiSsid: ""
    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    property int batteryPercent: -1
    property bool batteryCharging: false

    // Wallpaper path for the current session.
    property string wallpaper: "/usr/share/mylinux/wallpapers/mylinux-default.png"

    function closeAll(): void {
        launcherOpen = false
        calendarOpen = false
        powerMenuOpen = false
        notificationOpen = false
    }
}
