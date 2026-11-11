import QtQuick

import "../../theme"

Rectangle {
    id: root

    property string label: ""
    property string glyph: ""
    property bool danger: false
    signal triggered()

    implicitWidth: Math.max(96, buttonText.implicitWidth + Theme.spacing.xl * 2)
    implicitHeight: 34
    radius: Theme.radius.sm
    color: hover.hovered
        ? (root.danger ? Theme.color.primary : Theme.color.surfaceAlt)
        : "transparent"
    border.width: 1
    border.color: hover.hovered
        ? (root.danger ? Theme.color.primary : Theme.color.border)
        : Theme.color.borderDim

    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacing.sm

        Text {
            visible: root.glyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: hover.hovered && root.danger ? Theme.color.base
                : (root.danger ? Theme.color.primary : Theme.color.textMuted)
            font.family: Theme.font.mono
            font.pixelSize: Theme.font.sizeXs
        }

        Text {
            id: buttonText
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: hover.hovered && root.danger ? Theme.color.base
                : (hover.hovered ? Theme.color.text : Theme.color.textDim)
            font.family: Theme.font.mono
            font.pixelSize: Theme.font.sizeXs
            font.letterSpacing: 0.8
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}