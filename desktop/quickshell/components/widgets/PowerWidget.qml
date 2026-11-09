import QtQuick
import Quickshell

import "../../theme"

Item {
    id: root
    required property ShellState shellState

    implicitWidth: 30
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.centerIn: parent
        width: 30
        height: 26
        radius: Theme.radius.sm
        color: (hover.hovered || root.shellState.powerMenuOpen)
            ? Theme.color.primary
            : Theme.color.transparent

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Text {
            anchors.centerIn: parent
            text: "\u{f0425}"
            color: (hover.hovered || root.shellState.powerMenuOpen)
                ? Theme.color.base
                : Theme.color.primary
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeLg

            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.togglePowerMenu()
        }
    }
}