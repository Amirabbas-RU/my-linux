import QtQuick
import Quickshell

import "../../theme"

Item {
    id: root
    property string confirmAction: ""
    property int selectedIndex: 0
    signal actionRequested(string action)

    readonly property var actions: [
        { id: "lock", label: "Lock", glyph: "\u{f023}", hint: "Lock the session", destructive: false },
        { id: "logout", label: "Log out", glyph: "\u{f08ac}", hint: "End the Hyprland session", destructive: true },
        { id: "suspend", label: "Suspend", glyph: "\u{f186}", hint: "Suspend the machine", destructive: true },
        { id: "reboot", label: "Reboot", glyph: "\u{f05a8}", hint: "Restart the machine", destructive: true },
        { id: "shutdown", label: "Shut down", glyph: "\u{f0425}", hint: "Power off the machine", destructive: true }
    ]

    function request(action) {
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].id === action) {
                if (actions[i].destructive) {
                    root.confirmAction = action
                } else {
                    root.actionRequested(action)
                }
                return
            }
        }
    }

    function confirm() {
        const action = root.confirmAction
        root.confirmAction = ""
        if (action.length > 0) root.actionRequested(action)
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.lg
        spacing: Theme.spacing.md

        Text {
            width: parent.width
            text: root.confirmAction.length > 0 ? "Confirm action" : "Session"
            color: root.confirmAction.length > 0 ? Theme.color.danger : Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
        }

        Column {
            width: parent.width
            spacing: Theme.spacing.xs
            visible: root.confirmAction.length === 0

            Repeater {
                model: root.actions

                Rectangle {
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: 52
                    radius: Theme.radius.md
                    color: (actionHover.hovered || index === root.selectedIndex)
                        ? Theme.color.surfaceAlt : Theme.color.surface
                    border.width: index === root.selectedIndex ? 2 : 1
                    border.color: index === root.selectedIndex
                        ? (modelData.destructive ? Theme.color.danger : Theme.color.primary)
                        : (actionHover.hovered ? Theme.color.border : Theme.color.borderDim)

                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.lg
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.md

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            text: modelData.glyph
                            color: modelData.destructive ? Theme.color.danger : Theme.color.primary
                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.sizeLg
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: modelData.label
                                color: Theme.color.text
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeBase
                                font.weight: Theme.font.weightMedium
                            }

                            Text {
                                text: modelData.hint
                                color: Theme.color.textMuted
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeXs
                            }
                        }
                    }

                    HoverHandler { id: actionHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.request(modelData.id)
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: Theme.spacing.md
            visible: root.confirmAction.length > 0

            Rectangle {
                width: parent.width
                height: 64
                radius: Theme.radius.md
                color: Theme.color.danger
                border.width: 1
                border.color: Theme.color.danger

                Text {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.md
                    text: "This will " + root.confirmAction + " immediately. Unsaved work may be lost."
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeMd
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacing.sm

                Rectangle {
                    width: (parent.width - Theme.spacing.sm) / 2
                    height: 40
                    radius: Theme.radius.md
                    color: confirmHover.hovered ? Theme.color.danger : Theme.color.surface
                    border.width: 1
                    border.color: Theme.color.danger

                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: "Confirm"
                        color: confirmHover.hovered ? Theme.color.base : Theme.color.danger
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeMd
                        font.weight: Theme.font.weightMedium
                    }

                    HoverHandler { id: confirmHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirm()
                    }
                }

                Rectangle {
                    width: (parent.width - Theme.spacing.sm) / 2
                    height: 40
                    radius: Theme.radius.md
                    color: cancelHover.hovered ? Theme.color.surfaceAlt : Theme.color.surface
                    border.width: 1
                    border.color: Theme.color.border

                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.color.textDim
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeMd
                    }

                    HoverHandler { id: cancelHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmAction = ""
                    }
                }
            }
        }
    }
}