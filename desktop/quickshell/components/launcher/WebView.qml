import QtQuick
import Quickshell

import "../../theme"

Item {
    id: root
    property string provider: "DuckDuckGo"
    property var providers: []
    property string query: ""
    signal providerSelected(string name)
    signal openRequested()

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.lg
        spacing: Theme.spacing.md

        Rectangle {
            width: parent.width
            height: 74
            radius: Theme.radius.md
            color: Theme.color.surfaceAlt
            border.width: 1
            border.color: Theme.color.border

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.spacing.lg
                spacing: Theme.spacing.xs

                Text {
                    width: parent.width
                    text: "Search " + root.provider
                    color: Theme.color.primary
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeXs
                    font.weight: Theme.font.weightBold
                }

                Text {
                    width: parent.width
                    text: root.query.length > 0 ? root.query : "Type what you want to search for"
                    color: root.query.length > 0 ? Theme.color.text : Theme.color.textMuted
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeLg
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            width: parent.width
            text: "Provider"
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
        }

        Flow {
            width: parent.width
            spacing: Theme.spacing.sm

            Repeater {
                model: root.providers

                Rectangle {
                    required property var modelData
                    width: label.implicitWidth + Theme.spacing.lg * 2
                    height: 32
                    radius: Theme.radius.pill
                    color: modelData.name === root.provider
                        ? Theme.color.primary : (chipHover.hovered ? Theme.color.surfaceAlt : Theme.color.surface)
                    border.width: 1
                    border.color: modelData.name === root.provider ? Theme.color.primary : Theme.color.border

                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.name === root.provider ? Theme.color.base : Theme.color.textDim
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeSm
                        font.weight: modelData.name === root.provider
                            ? Theme.font.weightMedium : Theme.font.weightNormal
                    }

                    HoverHandler { id: chipHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.providerSelected(modelData.name)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: Theme.radius.md
            color: openHover.hovered && root.query.length > 0
                ? Theme.color.primary : Theme.color.surface
            border.width: 1
            border.color: root.query.length > 0 ? Theme.color.primary : Theme.color.border
            opacity: root.query.length > 0 ? 1.0 : 0.45

            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

            Text {
                anchors.centerIn: parent
                text: "Open in browser"
                color: openHover.hovered && root.query.length > 0 ? Theme.color.base : Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeMd
                font.weight: Theme.font.weightMedium
            }

            HoverHandler { id: openHover }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.query.length > 0
                onClicked: root.openRequested()
            }
        }
    }
}