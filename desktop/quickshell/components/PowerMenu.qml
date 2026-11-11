import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: root.shellState.powerMenuOpen || card.opacity > 0.002
    focusable: root.shellState.powerMenuOpen
    WlrLayershell.namespace: "mylinux-session"
    WlrLayershell.layer: WlrLayer.Overlay

    property string confirmAction: ""

    Process {
        id: actionProc
        running: false
        command: []
    }

    function runAction(cmd): void {
        actionProc.command = cmd
        actionProc.running = true
        root.shellState.powerMenuOpen = false
    }

    function doConfirm(): void {
        const a = confirmAction
        confirmAction = ""
        if (a === "logout") runAction(["hyprctl", "dispatch", "hl.dsp.exit()"])
        else if (a === "suspend") runAction(["systemctl", "suspend"])
        else if (a === "reboot") runAction(["systemctl", "reboot"])
        else if (a === "shutdown") runAction(["systemctl", "poweroff"])
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.shellState.powerMenuOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                easing.type: Theme.motion.easeOut
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.shellState.powerMenuOpen = false
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 420
        height: content.implicitHeight + Theme.spacing.xxl * 2
        radius: Theme.radius.xl
        color: Theme.color.surface
        border.color: Theme.color.border
        border.width: 1

        opacity: root.shellState.powerMenuOpen ? 1.0 : 0.0
        scale: root.shellState.powerMenuOpen ? 1.0 : 0.96
        Behavior on opacity {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                easing.type: Theme.motion.easeOut
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                easing.type: Theme.motion.easeOut
            }
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - Theme.spacing.xxl * 2
            spacing: Theme.spacing.lg

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MyLinux"
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeH2
                font.weight: Theme.font.weightBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.confirmAction === "" ? "Session" : ("Confirm " + root.confirmAction + "?")
                color: root.confirmAction === "" ? Theme.color.textMuted : Theme.color.danger
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeSm
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacing.sm
                visible: root.confirmAction === ""

                ActionButton { glyph: "\u{f023}"; label: "Lock"; onTriggered: root.runAction(["loginctl", "lock-session"]) }
                ActionButton { glyph: "\u{f08ac}"; label: "Logout"; onTriggered: root.confirmAction = "logout" }
                ActionButton { glyph: "\u{f186}"; label: "Suspend"; onTriggered: root.confirmAction = "suspend" }
                ActionButton { glyph: "\u{f05a8}"; label: "Reboot"; onTriggered: root.confirmAction = "reboot" }
                ActionButton { glyph: "\u{f0425}"; label: "Shutdown"; onTriggered: root.confirmAction = "shutdown" }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacing.sm
                visible: root.confirmAction !== ""

                ActionButton { glyph: "\u{f00c}"; label: "Confirm"; accent: true; onTriggered: root.doConfirm() }
                ActionButton { glyph: "\u{f00d}"; label: "Cancel"; onTriggered: root.confirmAction = "" }
            }
        }
    }

    component ActionButton: Rectangle {
        id: btn
        property string glyph: ""
        property string label: ""
        property bool accent: false
        signal triggered()

        width: 70
        height: 74
        radius: Theme.radius.md
        color: hover.hovered
            ? (accent ? Theme.color.primary : Theme.color.surfaceAlt)
            : Theme.color.base
        border.width: 1
        border.color: hover.hovered ? Theme.color.primary : Theme.color.border

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing.xxs

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.glyph
                color: (hover.hovered && btn.accent) ? Theme.color.base : Theme.color.primary
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeH2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.label
                color: (hover.hovered && btn.accent) ? Theme.color.base : Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
            }
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.triggered()
        }
    }
}