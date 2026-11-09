import QtQuick
import Quickshell

import "../../theme"

Item {
    id: root

    property string glyph: ""
    property string label: ""
    property string tooltip: ""
    property bool active: false
    property bool interactive: true
    property color activeColor: Theme.color.accent
    property color idleColor: Theme.color.text
    signal activated()

    implicitWidth: Math.max(24, inner.implicitWidth + Theme.spacing.sm * 2)
    implicitHeight: Theme.barHeight

    Rectangle {
        id: chrome
        anchors.centerIn: parent
        width: parent.implicitWidth
        height: 26
        radius: Theme.radius.sm
        color: (root.interactive && hover.hovered)
            ? Theme.color.surfaceAlt
            : Theme.color.transparent

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Row {
            id: inner
            anchors.centerIn: parent
            spacing: Theme.spacing.xxs

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: root.active ? root.activeColor : root.idleColor
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeLg

                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                visible: root.label !== ""
                color: Theme.color.textDim
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
            }
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.activated()
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: Theme.spacing.xs
            z: 100
            visible: hover.hovered && root.tooltip !== ""
            width: tipText.implicitWidth + Theme.spacing.sm * 2
            height: tipText.implicitHeight + Theme.spacing.xxs * 2
            radius: Theme.radius.sm
            color: Theme.color.surfaceAlt
            border.color: Theme.color.border
            border.width: 1

            Text {
                id: tipText
                anchors.centerIn: parent
                text: root.tooltip
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
            }
        }
    }
}