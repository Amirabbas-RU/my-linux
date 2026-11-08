import QtQuick

import "../../theme"

// The MyLinux brand mark: a stylised sunrise/terminal glyph plus wordmark.
Row {
    id: brand
    spacing: Theme.spacing.sm

    Item {
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.centerIn: parent
            width: 16
            height: 16
            radius: 4
            color: Theme.color.primary
            rotation: 45
        }
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 2
            color: Theme.color.base
            rotation: 45
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "MyLinux"
        color: Theme.color.text
        font.family: Theme.font.uiFamily
        font.pixelSize: Theme.font.sizeMd
        font.weight: Theme.font.weightBold
        font.letterSpacing: 0.5
    }
}
