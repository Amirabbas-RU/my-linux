import QtQuick
import Quickshell
import Quickshell.Networking

import "../../theme"

StatusButton {
    id: root
    required property ShellState shellState

    readonly property var wifiDevice: {
        const list = Networking.devices ? Networking.devices.values : []
        if (!list) return null
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi) return list[i]
        }
        return null
    }
    readonly property var wiredDevice: {
        const list = Networking.devices ? Networking.devices.values : []
        if (!list) return null
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wired) return list[i]
        }
        return null
    }
    readonly property string ssid: {
        if (!wifiDevice) return ""
        const nets = wifiDevice.networks ? wifiDevice.networks.values : []
        if (!nets) return ""
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i].name || ""
        }
        return ""
    }
    readonly property bool wiredUp: wiredDevice ? wiredDevice.connected : false

    glyph: {
        if (root.wiredUp) return "\u{f0e8}"
        if (root.ssid !== "") return "\u{f1eb}"
        if (Networking.wifiEnabled) return "\u{f05a9}"
        return "\u{f05aa}"
    }
    active: root.wiredUp || root.ssid !== ""
    activeColor: Theme.color.text
    tooltip: root.ssid !== "" ? root.ssid : (root.wiredUp ? "Wired" : "Disconnected")

    onActivated: root.shellState.toggleNetwork()
}