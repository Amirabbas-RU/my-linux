import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: root.shellState.calendarOpen || card.opacity > 0.002
    focusable: root.shellState.calendarOpen
    WlrLayershell.namespace: "mylinux-calendar"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property var clk: clock

    SystemClock {
        id: clock
        enabled: root.shellState.calendarOpen
        precision: SystemClock.Minutes
    }

    property string calText: ""

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.shellState.calendarOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                easing.type: Theme.motion.easeOut
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.shellState.calendarOpen = false
        }
    }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.topMargin: 66
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320
        height: body.implicitHeight + Theme.spacing.xl * 2
        radius: Theme.radius.lg
        color: Theme.color.surface
        border.color: Theme.color.border
        border.width: 1

        opacity: root.shellState.calendarOpen ? 1.0 : 0.0
        scale: root.shellState.calendarOpen ? 1.0 : 0.96
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                easing.type: Theme.motion.easeOut
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                easing.type: Theme.motion.easeOut
            }
        }

        Column {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.spacing.xl
            spacing: Theme.spacing.md

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.clk.date, "MMMM yyyy")
                color: Theme.color.primary
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeLg
                font.weight: Theme.font.weightBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.clk.date, "dddd dd")
                color: Theme.color.textDim
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeMd
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.color.border
            }

            Text {
                width: parent.width
                text: root.calText !== "" ? root.calText : " "
                color: Theme.color.text
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.sizeSm
                lineHeight: 1.4
            }
        }
    }

    Timer {
        interval: 60000
        running: root.shellState.calendarOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: calProc.running = true
    }

    Process {
        id: calProc
        running: root.shellState.calendarOpen
        command: ["cal"]
        stdout: StdioCollector {
            onStreamFinished: root.calText = text
        }
    }
}