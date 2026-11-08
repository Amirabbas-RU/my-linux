import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

// Bluetooth status via rfkill/bluetoothctl.
Item {
    id: bt
    required property ShellState shellState
    implicitWidth: icon.implicitWidth + Theme.spacing.sm * 2
    implicitHeight: Theme.iconSize + Theme.spacing.sm

    Process {
        id: poll
        command: ["sh", "-c", "rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: no' && echo on || echo off"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: bt.shellState.bluetoothEnabled = text.trim() === "on"
        }
    }

    Timer { interval: 6000; running: true; repeat: true; onTriggered: poll.running = true }

    Text {
        id: icon
        anchors.centerIn: parent
        color: bt.shellState.bluetoothEnabled ? Theme.color.accent : Theme.color.textMuted
        font.family: Theme.font.family
        font.pixelSize: Theme.font.sizeMd
        text: "\u{F00AF}"
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    TapHandler { onTapped: Quickshell.execDetached(["blueman-manager"]) }
}
