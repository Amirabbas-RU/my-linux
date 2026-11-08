import QtQuick

import "../../theme"

// Small floating tooltip used by bar widgets. Rendered by the parent window
// because panel surfaces cannot create their own top-level popups on Wayland.
Rectangle {
    id: tooltip
    property string text: ""
    property bool visible: false

    anchors.horizontalCenter: parent.horizontalCenter

    implicitWidth: label.implicitWidth + Theme.spacing.md * 2
    implicitHeight: label.implicitHeight + Theme.spacing.xs * 2
    radius: Theme.radius.sm
    color: Theme.color.overlay
    border.color: Theme.color.border
    border.width: 1
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: tooltip.text
        color: Theme.color.text
        font.family: Theme.font.uiFamily
        font.pixelSize: Theme.font.sizeSm
    }
}
