import QtQuick
import Quickshell

import "../../theme"

Item {
    id: root
    property var entries: []
    property bool available: true
    property string query: ""
    property int selectedIndex: 0
    signal copyRequested(string id)
    signal clearRequested()

    function positionTo(index) {
        list.positionViewAtIndex(index, ListView.Contain)
    }

    function filtered() {
        const out = []
        const needle = String(root.query || "").toLowerCase()
        for (let i = 0; i < root.entries.length; i++) {
            const entry = root.entries[i]
            if (needle.length === 0 || String(entry.preview).toLowerCase().indexOf(needle) !== -1) out.push(entry)
        }
        return out
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.lg
        spacing: Theme.spacing.md

        Row {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!root.available) return "cliphist / wl-clipboard not available"
                    const shown = root.filtered().length
                    if (root.query.length > 0) {
                        return shown + " of " + root.entries.length + (root.entries.length === 1 ? " entry" : " entries")
                    }
                    return root.entries.length + (root.entries.length === 1 ? " entry" : " entries")
                }
                color: root.available ? Theme.color.textMuted : Theme.color.warning
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
            }

            Item { width: parent.width - clearButton.width - 120; height: 1 }

            Rectangle {
                id: clearButton
                anchors.verticalCenter: parent.verticalCenter
                width: clearLabel.implicitWidth + Theme.spacing.lg * 2
                height: 28
                radius: Theme.radius.pill
                color: clearHover.hovered ? Theme.color.danger : Theme.color.surface
                border.width: 1
                border.color: clearHover.hovered ? Theme.color.danger : Theme.color.border
                opacity: root.entries.length > 0 ? 1.0 : 0.45

                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear history"
                    color: clearHover.hovered ? Theme.color.base : Theme.color.textDim
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeXs
                    font.weight: Theme.font.weightMedium
                }

                HoverHandler { id: clearHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.entries.length > 0
                    onClicked: root.clearRequested()
                }
            }
        }

        ListView {
            id: list
            width: parent.width
            height: Math.max(0, root.height - 130)
            clip: true
            spacing: Theme.spacing.xxs
            model: root.filtered()
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                required property var modelData
                required property int index
                width: list.width
                height: 46

                readonly property bool highlighted: index === root.selectedIndex

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.sm
                    color: (entryHover.hovered || highlighted) ? Theme.color.surfaceAlt : Theme.color.transparent
                    border.width: highlighted ? 1 : 0
                    border.color: Theme.color.accent
                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.spacing.md
                    anchors.rightMargin: Theme.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.preview
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeMd
                    elide: Text.ElideRight
                }

                HoverHandler { id: entryHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copyRequested(modelData.id)
                }
            }
        }

        Text {
            width: parent.width
            visible: root.available && root.filtered().length === 0
            text: root.entries.length === 0 ? "Clipboard history is empty" : "No matching entries"
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
        }
    }
}