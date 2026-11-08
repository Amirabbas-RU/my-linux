import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../theme"

// System tray: renders StatusNotifierItems registered on the session bus.
Row {
    id: tray
    required property ShellState shellState
    spacing: Theme.spacing.xs
    visible: repeater.count > 0

    Repeater {
        id: repeater
        model: SystemTray.items

        Item {
            required property var modelData
            width: Theme.iconSize
            height: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: modelData.icon
                sourceSize.width: Theme.iconSize
                sourceSize.height: Theme.iconSize
                smooth: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: parent.children[0].status !== Image.Ready
                text: ""
                color: Theme.color.textDim
            }

            HoverHandler { id: trayHover }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (event) => {
                    if (event.button === Qt.LeftButton && modelData.activate)
                        modelData.activate()
                }
            }
        }
    }
}
