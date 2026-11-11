import QtQuick

import "../../theme"

Item {
    id: root

    property string label: ""
    property string hint: ""
    property int value: 0
    property int from: 0
    property int to: 100
    property string suffix: ""
    signal moved(int value)

    implicitHeight: content.implicitHeight

    Column {
        id: content
        width: parent.width
        spacing: Theme.spacing.sm

        SettingRow {
            width: parent.width
            label: root.label
            hint: root.hint
            value: root.value + root.suffix
        }

        Rectangle {
            id: track
            width: parent.width
            height: 26
            color: "transparent"

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                color: Theme.color.borderDim
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, handle.x + handle.width / 2)
                height: 1
                color: Theme.color.primary
            }

            Rectangle {
                id: handle
                anchors.verticalCenter: parent.verticalCenter
                x: {
                    const span = root.to - root.from
                    const ratio = span === 0 ? 0 : (root.value - root.from) / span
                    return Math.max(0, Math.min(track.width - width, ratio * (track.width - width)))
                }
                width: 10
                height: 18
                color: dragging.pressed ? Theme.color.primary : Theme.color.text
                border.width: 1
                border.color: Theme.color.border

                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
            }

            MouseArea {
                id: dragging
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                cursorShape: Qt.SizeHorCursor

                function applyAt(px) {
                    const usable = Math.max(1, track.width - 10)
                    const ratio = Math.max(0, Math.min(1, (px - 5) / usable))
                    const next = Math.round(root.from + ratio * (root.to - root.from))
                    if (next !== root.value) root.moved(next)
                }

                onPressed: function (mouse) { applyAt(mouse.x) }
                onPositionChanged: function (mouse) { if (pressed) applyAt(mouse.x) }
            }
        }
    }
}