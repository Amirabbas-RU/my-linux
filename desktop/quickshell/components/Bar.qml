// MyLinux top panel.
//
// A single WlrLayerShell surface anchored to the top edge that composes the
// shell's always-visible controls: brand, workspaces, clock/calendar,
// system tray and the right-hand status cluster.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../theme"
import "../components/widgets"

PanelWindow {
    id: bar
    required property ShellState shellState

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: Theme.color.transparent

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: Theme.barMargin
        anchors.topMargin: Theme.barMargin
        color: Theme.color.surface
        radius: Theme.radius.pill
        border.color: Theme.color.border
        border.width: 1

        // Left cluster: brand + workspaces.
        Row {
            id: leftCluster
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing.md

            BrandMark {}
            WorkspaceWidget { shellState: bar.shellState }
        }

        // Centre cluster: clock / calendar.
        ClockWidget {
            id: clockWidget
            anchors.centerIn: parent
            shellState: bar.shellState
            onToggled: bar.shellState.calendarOpen = !bar.shellState.calendarOpen
        }

        // Right cluster: status + tray + power.
        Row {
            id: rightCluster
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing.sm

            TrayWidget { shellState: bar.shellState }
            NetworkWidget { shellState: bar.shellState }
            BluetoothWidget { shellState: bar.shellState }
            VolumeWidget { shellState: bar.shellState }
            BrightnessWidget { shellState: bar.shellState }
            BatteryWidget { shellState: bar.shellState }
            PowerWidget {
                shellState: bar.shellState
                onToggled: bar.shellState.powerMenuOpen = !bar.shellState.powerMenuOpen
            }
        }
    }
}
