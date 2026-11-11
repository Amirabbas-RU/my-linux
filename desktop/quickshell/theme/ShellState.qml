import QtQuick
import Quickshell

QtObject {
    id: state

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool calendarOpen: false
    property bool powerMenuOpen: false
    property bool notificationCenterOpen: false
    property bool settingsOpen: false
    property bool networkPopupOpen: false
    property bool volumePopupOpen: false
    property string settingsPage: "appearance"

    property string launcherMode: "apps"
    property string launcherQuery: ""

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

    property string wallpaper: ""
    property string searchProvider: "DuckDuckGo"

    function closeAll(): void {
        launcherOpen = false
        controlCenterOpen = false
        calendarOpen = false
        powerMenuOpen = false
        notificationCenterOpen = false
        settingsOpen = false
        networkPopupOpen = false
        volumePopupOpen = false
    }

    function toggleLauncher(): void {
        const open = !launcherOpen
        closeAll()
        launcherOpen = open
        if (open) {
            launcherMode = "apps"
            launcherQuery = ""
        }
    }

    function openLauncher(mode, query): void {
        closeAll()
        const m = mode ? String(mode) : "apps"
        const q = query ? String(query) : ""
        if (m === "apps") {
            launcherMode = "apps"
            launcherQuery = q
        } else {
            const prefixes = {
                calc: "=", web: "?", wall: "wall:", clip: "clip:", session: "session:"
            }
            launcherMode = m
            launcherQuery = (prefixes[m] || "") + q
        }
        launcherOpen = true
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

    function toggleSettings(): void {
        const open = !settingsOpen
        closeAll()
        settingsOpen = open
    }

    function toggleNetwork(): void {
        const open = !networkPopupOpen
        closeAll()
        networkPopupOpen = open
    }

    function toggleVolume(): void {
        const open = !volumePopupOpen
        closeAll()
        volumePopupOpen = open
    }

    function openSettings(page): void {
        closeAll()
        if (page && String(page).length > 0) settingsPage = String(page)
        settingsOpen = true
    }
}