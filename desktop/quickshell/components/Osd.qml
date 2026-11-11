import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    focusable: false
    visible: root.showing
    WlrLayershell.namespace: "mylinux-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    property string kind: "volume"
    property int value: 0
    property bool showing: false

    readonly property var sink: Pipewire.defaultAudioSink

    function showVolume(): void {
        const pct = root.sink && root.sink.audio ? Math.round(root.sink.audio.volume * 100) : 0
        root.show("volume", pct)
    }

    function show(k, v): void {
        root.kind = k
        root.value = v
        root.showing = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.showing = false
    }

    Item {
        anchors.centerIn: parent
        width: 240
        height: 84
        opacity: root.showing ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.fast
                easing: Theme.motion.easeOut
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.lg
            color: Theme.color.surface
            border.color: Theme.color.borderDim
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacing.lg
                spacing: Theme.spacing.sm

                Row {
                    spacing: Theme.spacing.sm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.kind === "volume" ? "\u{f057e}" : "\u{f00df}"
                        color: Theme.color.primary
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeLg
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.kind === "volume" ? "Volume" : "Brightness"
                        color: Theme.color.textDim
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeSm
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.value + "%"
                        color: Theme.color.text
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.sizeSm
                        font.weight: Theme.font.weightBold
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: Theme.radius.pill
                    color: Theme.color.surfaceAlt

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.value / 100))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.color.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: root.shellState.reducedMotion ? 0 : Theme.motion.fast
                                easing: Theme.motion.easeOut
                            }
                        }
                    }
                }
            }
        }
    }
}