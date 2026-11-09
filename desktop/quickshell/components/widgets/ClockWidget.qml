import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

Item {
    id: root
    required property ShellState shellState

    SystemClock {
        id: clock
        enabled: true
        precision: SystemClock.Minutes
    }

    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string dateText: Qt.formatDateTime(clock.date, "ddd dd MMM")

    implicitWidth: inner.implicitWidth + Theme.spacing.md * 2
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.centerIn: parent
        width: parent.implicitWidth
        height: 26
        radius: Theme.radius.sm
        color: hover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Row {
            id: inner
            anchors.centerIn: parent
            spacing: Theme.spacing.sm

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeText
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeMd
                font.weight: Theme.font.weightBold
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateText
                color: Theme.color.textMuted
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
            }
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.toggleCalendar()
        }
    }
}