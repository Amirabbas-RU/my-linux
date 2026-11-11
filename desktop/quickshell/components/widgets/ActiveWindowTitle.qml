import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../../theme"

Item {
    id: root
    required property ShellState shellState

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property string title: toplevel ? (toplevel.title || "") : ""
    readonly property string appId: toplevel ? (toplevel.appId || "") : ""

    implicitWidth: Math.min(360, row.implicitWidth)
    implicitHeight: Theme.barHeight
    clip: true

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing.sm

        Image {
            id: icon
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            source: root.appId !== "" ? Quickshell.iconPath(root.appId, true) : ""
            sourceSize.width: 16
            sourceSize.height: 16
            smooth: true
            visible: status === Image.Ready && root.title !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 320)
            text: root.title
            color: Theme.color.textDim
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeMd
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: root.title !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "MyLinux"
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeMd
            font.weight: Theme.font.weightMedium
            visible: root.title === ""
        }
    }
}