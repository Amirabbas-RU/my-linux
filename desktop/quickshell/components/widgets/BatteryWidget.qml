import QtQuick
import Quickshell
import Quickshell.Services.UPower

import "../../theme"

StatusButton {
    id: root
    required property ShellState shellState

    readonly property var device: UPower.displayDevice
    readonly property bool present: device ? device.isLaptopBattery : false
    readonly property int percent: device ? Math.round(device.percentage) : -1
    readonly property bool charging: device ? (device.state === UPowerDeviceState.Charging) : false

    visible: root.present
    width: visible ? implicitWidth : 0

    glyph: {
        if (root.charging) return "\u{f0084}"
        if (root.percent < 20) return "\u{f007a}"
        if (root.percent < 50) return "\u{f007b}"
        if (root.percent < 80) return "\u{f007c}"
        return "\u{f007d}"
    }
    active: root.charging
    activeColor: Theme.color.success
    tooltip: root.present ? (root.percent + "%" + (root.charging ? " charging" : "")) : ""
    label: root.present ? (root.percent + "%") : ""

    onActivated: root.shellState.toggleControlCenter()
}