import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../theme"

Row {
    id: root
    required property ShellState shellState
    spacing: Theme.spacing.xxs
    visible: repeater.count > 0

    Repeater {
        id: repeater
        model: SystemTray.items

        Item {
            id: entry
            required property var modelData
            width: 24
            height: Theme.barHeight

            Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: Theme.radius.sm
                color: trayHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent

                Image {
                    id: logo
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: entry.modelData.icon
                    sourceSize.width: 16
                    sourceSize.height: 16
                    smooth: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: logo.status !== Image.Ready
                    text: "\u{f0090}"
                    color: Theme.color.textDim
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeMd
                }

                HoverHandler { id: trayHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (event) => {
                        if (event.button === Qt.LeftButton && entry.modelData.activate)
                            entry.modelData.activate()
                        else if (event.button === Qt.RightButton && entry.modelData.secondaryActivate)
                            entry.modelData.secondaryActivate()
                    }
                }
            }
        }
    }
}