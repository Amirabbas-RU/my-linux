import QtQuick

import "../../theme"

Item {
    id: root

    property string title: ""
    default property alias content: body.data

    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacing.lg

        Item {
            width: parent.width
            implicitHeight: header.implicitHeight

            Row {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacing.md

                Text {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title.toUpperCase()
                    color: Theme.color.textFaint
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.sizeXs
                    font.letterSpacing: 1.4
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, header.width - titleText.implicitWidth - header.spacing)
                    height: 1
                    color: Theme.color.borderDim
                }
            }
        }

        Column {
            id: body
            width: parent.width
            spacing: Theme.spacing.lg
        }
    }
}