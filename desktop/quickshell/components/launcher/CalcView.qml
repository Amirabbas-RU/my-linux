import QtQuick
import Quickshell

import "../../theme"

Item {
    id: view
    property string expression: ""
    property var result: null
    signal copyRequested()

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.lg
        spacing: Theme.spacing.md

        Rectangle {
            width: parent.width
            height: 82
            radius: Theme.radius.lg
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
                    text: view.expression.length > 0 ? view.expression : "Type an expression"
                    color: view.expression.length > 0 ? Theme.color.textDim : Theme.color.textMuted
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.sizeBase
                    elide: Text.ElideLeft
                }

                Text {
                    width: parent.width
                    text: {
                        if (view.expression.length === 0) return " "
                        if (!view.result) return " "
                        if (view.result.ok) return "= " + view.result.text
                        return view.result.error
                    }
                    color: view.result && view.result.ok ? Theme.color.primary : Theme.color.danger
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.sizeH2
                    font.weight: Theme.font.weightBold
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            width: parent.width
            height: copyRow.implicitHeight + Theme.spacing.md * 2
            radius: Theme.radius.md
            color: copyHover.hovered && view.result && view.result.ok
                ? Theme.color.surfaceAlt : Theme.color.surface
            border.width: 1
            border.color: Theme.color.border
            opacity: view.result && view.result.ok ? 1.0 : 0.45

            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

            Row {
                id: copyRow
                anchors.centerIn: parent
                spacing: Theme.spacing.sm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u2398"
                    color: Theme.color.primary
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeBase
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Copy result"
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeMd
                }
            }

            HoverHandler { id: copyHover }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: view.result && view.result.ok
                onClicked: view.copyRequested()
            }
        }

        Text {
            width: parent.width
            text: "Supports + - * / % ^, parentheses, functions (sqrt, sin, log, min, max, ...), constants pi and e, and postfix factorial."
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
            wrapMode: Text.WordWrap
        }
    }
}