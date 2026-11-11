import QtQuick

import "../../theme"

Rectangle {
    id: root

    property string label: ""
    property bool active: false
    signal triggered()

    implicitWidth: chipText.implicitWidth + Theme.spacing.lg * 2
    implicitHeight: 30
    radius: Theme.radius.sm
    color: root.active ? Theme.color.primary : Theme.color.base
    border.width: 1
    border.color: root.active ? Theme.color.primary
        : (hover.hovered ? Theme.color.border : Theme.color.borderDim)

    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

    Text {
        id: chipText
        anchors.centerIn: parent
        text: root.label
        color: root.active ? Theme.color.base
            : (hover.hovered ? Theme.color.text : Theme.color.textMuted)
        font.family: Theme.font.mono
        font.pixelSize: Theme.font.sizeXs
        font.letterSpacing: 0.8

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}