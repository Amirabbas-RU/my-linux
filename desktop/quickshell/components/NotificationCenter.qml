import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; right: true }
    margins {
        top: Theme.barHeight + Theme.barTopMargin * 2 + Theme.spacing.sm
        right: Theme.barMargin
    }
    implicitWidth: 340
    implicitHeight: Math.max(1, column.implicitHeight)
    color: Theme.color.transparent
    exclusiveZone: 0
    focusable: root.shellState.notificationCenterOpen
    visible: cardModel.count > 0 || root.shellState.notificationCenterOpen
    WlrLayershell.namespace: "mylinux-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: function(n) {
            n.tracked = true
            root.add(n)
        }
    }

    ListModel { id: cardModel }

    onVisibleChanged: root.shellState.notificationCount = cardModel.count

    function add(n): void {
        const timeout = n.expireTimeout > 0 ? n.expireTimeout : 6000
        cardModel.append({
            appName: n.appName || "",
            appIcon: n.appIcon || "",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency,
            resident: n.resident === true,
            timeout: timeout,
            handle: n
        })
        root.shellState.notificationCount = cardModel.count
    }

    function removeAt(i): void {
        if (i < 0 || i >= cardModel.count) return
        const item = cardModel.get(i)
        if (item.handle) item.handle.dismiss()
        cardModel.remove(i)
        root.shellState.notificationCount = cardModel.count
    }

    function clearAll(): void {
        while (cardModel.count > 0) removeAt(0)
    }

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacing.sm

        Repeater {
            model: cardModel

            Rectangle {
                id: card
                required property int index
                required property string appName
                required property string appIcon
                required property string summary
                required property string body
                required property int urgency
                required property bool resident
                required property int timeout

                width: column.width
                height: content.implicitHeight + Theme.spacing.md * 2
                radius: Theme.radius.md
                color: Theme.color.surface
                border.width: 1
                border.color: card.urgency === NotificationUrgency.Critical
                    ? Theme.color.danger
                    : Theme.color.border

                Column {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.md
                    spacing: Theme.spacing.xs

                    Row {
                        width: parent.width
                        spacing: Theme.spacing.sm

                        Image {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            source: card.appIcon !== "" ? Quickshell.iconPath(card.appIcon, true) : ""
                            sourceSize.width: 16
                            sourceSize.height: 16
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.appName
                            color: Theme.color.textMuted
                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.sizeXs
                        }
                    }

                    Text {
                        width: parent.width
                        text: card.summary
                        color: Theme.color.text
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeMd
                        font.weight: Theme.font.weightBold
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: card.body
                        visible: text.length > 0
                        color: Theme.color.textDim
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeSm
                        wrapMode: Text.WordWrap
                    }
                }

                Timer {
                    interval: card.timeout
                    running: !card.resident
                    onTriggered: root.removeAt(card.index)
                }

                TapHandler { onTapped: root.removeAt(card.index) }
            }
        }
    }
}