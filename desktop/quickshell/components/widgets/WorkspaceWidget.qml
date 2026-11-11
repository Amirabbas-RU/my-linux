import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../../theme"

Row {
    id: root
    required property ShellState shellState
    spacing: Theme.spacing.xxs

    readonly property var wsList: Hyprland.workspaces ? (Hyprland.workspaces.values ? Hyprland.workspaces.values : []) : []
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    function occupied(id): bool {
        for (let i = 0; i < wsList.length; i++) {
            if (wsList[i].id === id) return true
        }
        return false
    }

    function focusWorkspace(id): void {
        focusProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"]
        focusProc.running = true
    }

    Process {
        id: focusProc
        running: false
    }

    Repeater {
        model: 10

        Item {
            id: cell
            required property int index
            readonly property int wsId: index + 1
            readonly property bool isFocused: root.focusedId === wsId
            readonly property bool isOccupied: root.occupied(wsId)

            width: isFocused ? 26 : 22
            height: Theme.barHeight

            Behavior on width {
                NumberAnimation {
                    duration: root.shellState.reducedMotion ? 0 : Theme.motion.fast
                    easing: Theme.motion.easeOut
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 24
                radius: Theme.radius.sm
                color: cell.isFocused
                    ? Theme.color.accent
                    : (cell.isOccupied ? Theme.color.surfaceAlt : Theme.color.transparent)
                border.width: cell.isOccupied && !cell.isFocused ? 1 : 0
                border.color: Theme.color.border

                Behavior on color {
                    ColorAnimation { duration: root.shellState.reducedMotion ? 0 : Theme.motion.fast }
                }

                Text {
                    anchors.centerIn: parent
                    text: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"][cell.wsId - 1]
                    color: cell.isFocused
                        ? Theme.color.base
                        : (cell.isOccupied ? Theme.color.text : Theme.color.textMuted)
                    font.family: Theme.font.cjk
                    font.pixelSize: Theme.font.sizeMd
                    font.weight: cell.isFocused ? Theme.font.weightBold : Theme.font.weightMedium
                }

                HoverHandler { id: hover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(cell.wsId)
                }
            }
        }
    }
}