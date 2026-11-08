import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

// Screen brightness via brightnessctl (sysfs backlight).
Item {
    id: brightness
    required property ShellState shellState
    implicitWidth: icon.implicitWidth + Theme.spacing.sm * 2
    implicitHeight: Theme.iconSize + Theme.spacing.sm

    Process {
        id: poll
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{print $4\" \"$3}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/^(\d+)%?\s*(\d+)%?/)
                if (m) brightness.shellState.brightness = parseInt(m[1])
            }
        }
    }

    function adjust(delta): void {
        const arg = delta > 0 ? "5%+" : "5%-"
        Quickshell.execDetached(["brightnessctl", "set", arg])
        refreshTimer.restart()
    }

    Timer { id: refreshTimer; interval: 150; onTriggered: poll.running = true }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: poll.running = true }

    Text {
        id: icon
        anchors.centerIn: parent
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.sizeMd
        text: {
            const b = brightness.shellState.brightness
            if (b < 15) return "\u{F00DD}"
            if (b < 55) return "\u{F00DE}"
            return "\u{F00DF}"
        }
    }

    WheelHandler { onWheel: (event) => brightness.adjust(event.angleDelta.y) }
}
