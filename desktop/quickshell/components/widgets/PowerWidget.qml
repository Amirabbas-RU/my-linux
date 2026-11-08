import QtQuick

import "../../theme"

// Power button that opens the session menu.
Item {
    id: power
    required property ShellState shellState
    signal toggled()

    implicitWidth: icon.implicitWidth + Theme.spacing.md * 2
    implicitHeight: Theme.iconSize + Theme.spacing.sm

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.pill
        color: hover.hovered ? Theme.color.primary : Theme.color.surfaceAlt
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Text {
            id: icon
            anchors.centerIn: parent
            text: "\u{F0425}"
            color: power.shellState.powerMenuOpen || hover.hovered ? Theme.color.base : Theme.color.primary
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeMd
            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
        }
        HoverHandler { id: hover }
        TapHandler { onTapped: power.toggled() }
    }
}
