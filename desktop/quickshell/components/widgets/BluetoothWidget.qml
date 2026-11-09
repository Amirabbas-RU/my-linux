import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

import "../../theme"

StatusButton {
    id: root
    required property ShellState shellState

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool haveAdapter: adapter !== null
    readonly property bool powered: haveAdapter ? (adapter.state === BluetoothAdapterState.Powered) : false

    visible: root.haveAdapter
    width: visible ? implicitWidth : 0

    glyph: powered ? "\u{f00af}" : "\u{f00b2}"
    active: powered
    activeColor: Theme.color.accent
    tooltip: !haveAdapter ? "No Bluetooth adapter" : (powered ? "Bluetooth on" : "Bluetooth off")

    onActivated: launcher.running = true

    Process {
        id: launcher
        running: false
        command: ["blueman-manager"]
    }
}