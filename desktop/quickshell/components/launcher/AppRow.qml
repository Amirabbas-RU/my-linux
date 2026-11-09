import QtQuick
import Quickshell

import "../../theme"

Item {
    id: row
    property var descriptor: null
    property bool active: false
    signal activated()
    signal toggledFavorite()

    height: 54

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.md
        color: row.active || rowHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent
        border.width: row.active ? 1 : 0
        border.color: Theme.color.border

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 20
        radius: 2
        color: Theme.color.primary
        opacity: row.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.md
        anchors.right: favoriteButton.left
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.md

        Item {
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 28
                height: 28
                sourceSize.width: 96
                sourceSize.height: 96
                smooth: true
                mipmap: true
                visible: source !== "" && status === Image.Ready
                source: row.descriptor && row.descriptor.icon
                    ? Quickshell.iconPath(row.descriptor.icon, true) : ""
            }

            Text {
                anchors.centerIn: parent
                visible: !appIcon.visible
                text: row.descriptor && row.descriptor.name ? row.descriptor.name.charAt(0).toUpperCase() : "?"
                color: Theme.color.primary
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeLg
                font.weight: Theme.font.weightBold
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 28 - Theme.spacing.md
            spacing: 1

            Text {
                width: parent.width
                text: row.descriptor ? (row.descriptor.name || "") : ""
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeBase
                font.weight: row.active ? Theme.font.weightMedium : Theme.font.weightNormal
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text.length > 0
                text: row.descriptor ? (row.descriptor.comment || row.descriptor.genericName || "") : ""
                color: Theme.color.textMuted
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        id: favoriteButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: Theme.radius.sm
        color: favHover.hovered ? Theme.color.base : Theme.color.transparent

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Text {
            anchors.centerIn: parent
            text: row.descriptor && row.descriptor.pinned ? "\u2605" : "\u2606"
            color: row.descriptor && row.descriptor.pinned ? Theme.color.primary : Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeBase
        }

        HoverHandler { id: favHover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggledFavorite()
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 34
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activated()
    }

    HoverHandler { id: rowHover }
}