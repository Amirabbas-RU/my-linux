import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

// Live clock for the top panel. Reads the system time via a Process poll so it
// works without the shell needing a compositor clock source, and writes the
// formatted strings into the shared ShellState for other components to read.
Item {
    id: clockWidget
    required property ShellState shellState

    signal toggled()

    implicitWidth: clockText.implicitWidth + Theme.spacing.lg * 2
    implicitHeight: Theme.barHeight - Theme.barMargin * 2

    Process {
        id: tick
        command: ["sh", "-c", "date '+%H:%M  %a %d %b'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                clockWidget.shellState.clock = text.trim()
            }
        }
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: tick.running = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.pill
        color: hover.hovered ? Theme.color.surfaceHi : Theme.color.transparent
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Text {
            id: clockText
            anchors.centerIn: parent
            text: clockWidget.shellState.clock !== "" ? clockWidget.shellState.clock : "--:--"
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeSm
            font.weight: Theme.font.weightMedium
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: clockWidget.toggled() }
    }
}
