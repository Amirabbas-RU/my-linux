import QtQuick
import Quickshell

import "../theme"

// Volume / brightness on-screen display.
//
// A centred pill that fades in whenever the volume or brightness changes and
// fades out again after a short delay. Values are read from ShellState, which
// the bar widgets keep up to date.
PanelWindow {
    id: osd
    required property ShellState shellState

    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: opacity > 0
    focusable: false

    property bool showing: false
    property string kind: "volume"
    property int value: 0

    opacity: showing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.motion.normal } }

    function ping(): void { show("volume", osd.shellState.volume) }
    function show(k, v): void {
        kind = k
        value = v
        showing = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: osd.showing = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 220
        height: 64
        radius: Theme.radius.lg
        color: Theme.color.surface
        border.color: Theme.color.border
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing.sm
            width: parent.width - Theme.spacing.xl

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: osd.kind === "volume" ? "\u{F057E}  Volume" : "\u{F00DF}  Brightness"
                color: Theme.color.textDim
                font.family: Theme.font.uiFamily
                font.pixelSize: Theme.font.sizeSm
            }
            Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: Theme.color.surfaceAlt
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, osd.value / 100))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.color.primary
                    Behavior on width { NumberAnimation { duration: Theme.motion.fast } }
                }
            }
        }
    }
}
