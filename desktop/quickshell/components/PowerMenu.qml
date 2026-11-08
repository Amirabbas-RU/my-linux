import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Session power menu: lock, logout, suspend, reboot, shutdown.
PanelWindow {
    id: powerMenu
    required property ShellState shellState

    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: shellState.powerMenuOpen
    focusable: shellState.powerMenuOpen

    function toggle(): void {
        const open = !shellState.powerMenuOpen
        shellState.closeAll()
        shellState.powerMenuOpen = open
    }
    function close(): void { shellState.powerMenuOpen = false }
    function run(cmd): void {
        close()
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        TapHandler { onTapped: powerMenu.close() }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: 320
        radius: Theme.radius.lg
        color: Theme.color.surface
        border.color: Theme.color.border
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing.lg

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MyLinux"
                color: Theme.color.text
                font.family: Theme.font.uiFamily
                font.pixelSize: Theme.font.sizeXl
                font.weight: Theme.font.weightBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Session"
                color: Theme.color.textMuted
                font.family: Theme.font.uiFamily
                font.pixelSize: Theme.font.sizeSm
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacing.md

                PowerAction { icon: "\u{F023}"; label: "Lock"; onActivated: powerMenu.run("loginctl lock-session") }
                PowerAction { icon: "\u{F08AC}"; label: "Logout"; onActivated: powerMenu.run("hyprctl dispatch exit") }
                PowerAction { icon: "\u{F05A8}"; label: "Reboot"; onActivated: powerMenu.run("systemctl reboot") }
                PowerAction { icon: "\u{F0425}"; label: "Shutdown"; onActivated: powerMenu.run("systemctl poweroff") }
            }
        }
    }

    component PowerAction: Rectangle {
        property string icon: ""
        property string label: ""
        signal activated()

        width: 84
        height: 84
        radius: Theme.radius.md
        color: pa.hovered ? Theme.color.surfaceHi : Theme.color.surfaceAlt
        border.width: 1
        border.color: pa.hovered ? Theme.color.primary : Theme.color.border
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing.xs
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: parent.parent.icon
                color: Theme.color.primary
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXl
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: parent.parent.label
                color: Theme.color.text
                font.family: Theme.font.uiFamily
                font.pixelSize: Theme.font.sizeXs
            }
        }
        HoverHandler { id: pa }
        TapHandler { onTapped: parent.activated() }
    }
}
