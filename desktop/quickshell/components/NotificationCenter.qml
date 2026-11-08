import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import "../theme"

// Notification daemon and popup stack.
//
// Quickshell's NotificationServer implements org.freedesktop.Notifications, so
// the shell becomes the session's notification daemon. Tracked notifications
// are rendered as a vertical stack of cards in the top-right corner.
PanelWindow {
    id: center
    required property ShellState shellState

    anchors { top: true; right: true }
    margins { top: Theme.barHeight + Theme.spacing.md; right: Theme.spacing.md }
    implicitWidth: 360
    implicitHeight: Math.min(stack.height, 600)
    color: Theme.color.transparent
    exclusiveZone: 0
    focusable: false

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
    }

    Column {
        id: stack
        width: parent.width
        spacing: Theme.spacing.sm

        Repeater {
            model: server.trackedNotifications

            Rectangle {
                required property var modelData
                width: stack.width
                height: content.implicitHeight + Theme.spacing.lg * 2
                radius: Theme.radius.md
                color: Theme.color.surface
                border.width: 1
                border.color: modelData.urgency === NotificationUrgency.Critical
                    ? Theme.color.danger
                    : Theme.color.border

                Column {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.lg
                    spacing: Theme.spacing.xs

                    Row {
                        spacing: Theme.spacing.sm
                        width: parent.width

                        Image {
                            width: 18; height: 18
                            source: modelData.appIcon !== "" ? Quickshell.iconPath(modelData.appIcon, true) : ""
                            visible: status === Image.Ready
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.appName
                            color: Theme.color.textMuted
                            font.family: Theme.font.uiFamily
                            font.pixelSize: Theme.font.sizeXs
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Text {
                        width: parent.width
                        text: modelData.summary
                        color: Theme.color.text
                        font.family: Theme.font.uiFamily
                        font.pixelSize: Theme.font.sizeMd
                        font.weight: Theme.font.weightBold
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: modelData.body
                        visible: text.length > 0
                        color: Theme.color.textDim
                        font.family: Theme.font.uiFamily
                        font.pixelSize: Theme.font.sizeSm
                        wrapMode: Text.WordWrap
                    }
                }

                Timer {
                    interval: Math.max(3000, modelData.expireTimeout)
                    running: true
                    onTriggered: modelData.expire()
                }

                TapHandler { onTapped: modelData.dismiss() }
            }
        }
    }
}
