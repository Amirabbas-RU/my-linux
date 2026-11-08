import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

// Volume control bound to PipeWire via wpctl. Polls the default sink and lets
// the user adjust it with the scroll wheel or by clicking to mute.
Item {
    id: volume
    required property ShellState shellState
    implicitWidth: icon.implicitWidth + Theme.spacing.sm * 2
    implicitHeight: Theme.iconSize + Theme.spacing.sm

    Process {
        id: poll
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                const m = t.match(/Volume:\s*([0-9.]+)/)
                if (m) volume.shellState.volume = Math.round(parseFloat(m[1]) * 100)
                volume.shellState.muted = t.includes("[MUTED]")
            }
        }
    }

    function adjust(delta): void {
        const step = delta > 0 ? "5%+" : "5%-"
        Quickshell.launch(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", step])
        refreshTimer.restart()
    }
    function toggleMute(): void {
        Quickshell.launch(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        refreshTimer.restart()
    }

    Timer { id: refreshTimer; interval: 150; onTriggered: poll.running = true }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: poll.running = true }

    Text {
        id: icon
        anchors.centerIn: parent
        color: volume.shellState.muted ? Theme.color.textMuted : Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.sizeMd
        text: {
            if (volume.shellState.muted) return "\u{F0581}"
            const v = volume.shellState.volume
            if (v < 1) return "\u{F0580}"
            if (v < 50) return "\u{F057F}"
            return "\u{F057E}"
        }
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    WheelHandler {
        onWheel: (event) => volume.adjust(event.angleDelta.y)
    }
    TapHandler { onTapped: volume.toggleMute() }
}
