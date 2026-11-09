import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "../../theme"

StatusButton {
    id: root
    required property ShellState shellState

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false
    readonly property real volume: audio ? audio.volume : 0.0
    readonly property int percent: Math.round(volume * 100)

    glyph: {
        if (root.muted || root.percent === 0) return "\u{f0581}"
        if (root.percent < 34) return "\u{f0580}"
        if (root.percent < 67) return "\u{f057f}"
        return "\u{f057e}"
    }
    active: false
    activeColor: Theme.color.text
    tooltip: root.muted ? "Muted" : (root.percent + "%")

    onActivated: launcher.running = true

    WheelHandler {
        onWheel: (event) => {
            if (!root.audio) return
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05
            root.audio.volume = Math.max(0.0, Math.min(1.0, root.audio.volume + step))
        }
    }

    Process {
        id: launcher
        running: false
        command: ["pavucontrol"]
    }
}