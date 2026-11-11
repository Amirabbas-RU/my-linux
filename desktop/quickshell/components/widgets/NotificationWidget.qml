import QtQuick
import Quickshell

import "../../theme"

StatusButton {
    id: root
    required property ShellState shellState

    glyph: root.shellState.dnd ? "\u{f0097}" : "\u{f009a}"
    active: root.shellState.notificationCount > 0 && !root.shellState.dnd
    activeColor: Theme.color.primary
    tooltip: root.shellState.dnd ? "Do Not Disturb" : (root.shellState.notificationCount + " notifications")
    label: ""

    onActivated: root.shellState.notificationCenterOpen = !root.shellState.notificationCenterOpen

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 2
        width: 14
        height: 14
        radius: 7
        color: Theme.color.primary
        visible: root.shellState.notificationCount > 0
        z: 10

        Text {
            anchors.centerIn: parent
            text: root.shellState.notificationCount > 9 ? "9+" : root.shellState.notificationCount
            color: Theme.color.base
            font.family: Theme.font.family
            font.pixelSize: 9
            font.weight: Theme.font.weightBold
        }
    }
}