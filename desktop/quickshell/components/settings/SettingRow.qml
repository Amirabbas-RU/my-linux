import QtQuick

import "../../theme"

Item {
    id: root

    property string label: ""
    property string hint: ""
    property string value: ""

    implicitHeight: header.implicitHeight + Theme.spacing.sm

    Column {
        id: header
        width: parent.width
        spacing: 2

        Row {
            width: parent.width
            spacing: Theme.spacing.sm

            Text {
                id: labelText
                text: root.label.toUpperCase()
                color: Theme.color.textDim
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.sizeXs
                font.letterSpacing: 1.1
            }

            Item {
                width: Math.max(0, header.width - labelText.implicitWidth
                    - valueText.implicitWidth - (2 * Theme.spacing.sm))
                height: 1
            }

            Text {
                id: valueText
                text: root.value
                color: Theme.color.text
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.sizeXs
            }
        }

        Text {
            width: parent.width
            text: root.hint
            visible: root.hint.length > 0
            color: Theme.color.textFaint
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
            wrapMode: Text.WordWrap
        }
    }
}