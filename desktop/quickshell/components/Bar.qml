import QtQuick
import Quickshell
import Quickshell.Wayland

import "../theme"
import "widgets"

PanelWindow {
    id: bar
    required property ShellState shellState

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.barTopMargin * 2
    exclusiveZone: Theme.barHeight + Theme.barTopMargin * 2
    color: Theme.color.transparent
    WlrLayershell.namespace: "mylinux-bar"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: plate
        anchors.fill: parent
        anchors.topMargin: Theme.barTopMargin
        anchors.leftMargin: Theme.barMargin
        anchors.rightMargin: Theme.barMargin
        anchors.bottomMargin: Theme.barTopMargin
        radius: Theme.radius.md
        color: Theme.color.surface
        border.color: Theme.color.borderDim
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: parent.radius
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.color.transparent }
                GradientStop { position: 0.5; color: Theme.color.borderStrong }
                GradientStop { position: 1.0; color: Theme.color.transparent }
            }
        }

        Item {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            width: leftRow.implicitWidth
            height: parent.height

            Row {
                id: leftRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.md

                BrandMark { shellState: bar.shellState }
                WorkspaceWidget { shellState: bar.shellState }
            }
        }

        Item {
            id: centerSection
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.42, 380)
            height: parent.height

            ActiveWindowTitle {
                anchors.centerIn: parent
                shellState: bar.shellState
            }
        }

        Item {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing.sm
            anchors.verticalCenter: parent.verticalCenter
            width: rightRow.implicitWidth
            height: parent.height

            Row {
                id: rightRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.xxs

                TrayWidget { shellState: bar.shellState }
                NotificationWidget { shellState: bar.shellState }
                NetworkWidget { shellState: bar.shellState }
                BluetoothWidget { shellState: bar.shellState }
                VolumeWidget { shellState: bar.shellState }
                BatteryWidget { shellState: bar.shellState }
                ClockWidget { shellState: bar.shellState }
                PowerWidget { shellState: bar.shellState }
            }
        }
    }
}