import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../../theme"

// Workspace indicator driven by the Hyprland IPC service. Each dot is a
// workspace; the focused one is highlighted and urgent ones pulse.
Row {
    id: workspaces
    required property ShellState shellState
    spacing: Theme.spacing.xs
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            required property var modelData
            width: modelData.focused ? 22 : 8
            height: 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: modelData.focused
                ? Theme.color.primary
                : (modelData.urgent ? Theme.color.danger : Theme.color.textMuted)
            Behavior on width { NumberAnimation { duration: Theme.motion.normal; easing: Theme.motion.easeOut } }
            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.activate()
            }
        }
    }
}
