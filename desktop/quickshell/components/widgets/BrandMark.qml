import QtQuick
import Quickshell

import "../../theme"

Rectangle {
    id: root
    required property ShellState shellState

    width: 22
    height: 22
    radius: Theme.radius.sm
    color: Theme.color.transparent

    Rectangle {
        anchors.centerIn: parent
        width: 18
        height: 18
        radius: 4
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.color.primary }
            GradientStop { position: 1.0; color: Theme.color.accent }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 8
        height: 8
        radius: 2
        color: Theme.color.base
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.shellState.toggleLauncher()
    }
}