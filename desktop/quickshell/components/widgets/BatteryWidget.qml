import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

// Battery status. Hidden entirely on machines without a battery.
Item {
    id: battery
    required property ShellState shellState
    implicitWidth: icon.implicitWidth + Theme.spacing.sm * 2
    implicitHeight: Theme.iconSize + Theme.spacing.sm
    visible: battery.shellState.batteryPercent >= 0

    Process {
        id: poll
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null; cat /sys/class/power_supply/BAT*/status 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length >= 1 && lines[0].trim() !== "") {
                    battery.shellState.batteryPercent = parseInt(lines[0])
                    battery.shellState.batteryCharging = (lines[1] || "").includes("Charging")
                } else {
                    battery.shellState.batteryPercent = -1
                }
            }
        }
    }

    Timer { interval: 20000; running: true; repeat: true; onTriggered: poll.running = true }

    Text {
        id: icon
        anchors.centerIn: parent
        color: battery.shellState.batteryPercent < 15 ? Theme.color.danger : Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.sizeSm
        text: {
            const p = battery.shellState.batteryPercent
            const ch = battery.shellState.batteryCharging ? "\u{F0084}" : ""
            return ch + " " + p + "%"
        }
    }
}
