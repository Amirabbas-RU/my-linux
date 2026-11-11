import QtQuick
import Quickshell

import "../../theme"

Item {
    id: root
    property var wallpapers: []
    property string currentPath: ""
    property bool backendMissing: false
    property int selectedIndex: 0
    signal selected(string path)

    function positionTo(index) {
        grid.positionViewAtIndex(index, GridView.Contain)
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacing.lg
        spacing: Theme.spacing.sm

        Text {
            id: caption
            width: parent.width
            text: root.backendMissing
                ? "Wallpaper backend unavailable — start awww-daemon to enable switching"
                : root.wallpapers.length + (root.wallpapers.length === 1 ? " wallpaper" : " wallpapers")
            color: root.backendMissing ? Theme.color.warning : Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
            wrapMode: Text.WordWrap
        }

        GridView {
            id: grid
            width: parent.width
            height: parent.height - caption.height - Theme.spacing.sm
            cellWidth: Math.floor(width / 3)
            cellHeight: cellWidth * 9 / 16 + 34
            clip: true
            model: root.wallpapers
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                readonly property bool current: modelData.path === root.currentPath
                readonly property bool highlighted: index === root.selectedIndex

                Rectangle {
                    id: thumb
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.xxs
                    radius: Theme.radius.md
                    color: Theme.color.surfaceAlt
                    border.width: current ? 2 : (highlighted ? 2 : 1)
                    border.color: current ? Theme.color.primary
                        : (highlighted ? Theme.color.accent
                        : (cellHover.hovered ? Theme.color.border : Theme.color.borderDim))
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

                    Image {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 4
                        height: parent.height - 30
                        source: modelData.file
                        sourceSize.width: 480
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: Theme.spacing.sm
                        anchors.bottomMargin: Theme.spacing.xs
                        text: modelData.name
                        color: Theme.color.text
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeXs
                        font.weight: current ? Theme.font.weightMedium : Theme.font.weightNormal
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spacing.sm
                        width: currentBadge.implicitWidth + Theme.spacing.sm * 2
                        height: 20
                        radius: Theme.radius.pill
                        color: Theme.color.primary
                        visible: current

                        Text {
                            id: currentBadge
                            anchors.centerIn: parent
                            text: "Active"
                            color: Theme.color.base
                            font.family: Theme.font.family
                            font.pixelSize: 10
                            font.weight: Theme.font.weightBold
                        }
                    }

                    HoverHandler { id: cellHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selected(modelData.path)
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.wallpapers.length === 0
            text: "No wallpapers found in /usr/share/mylinux/wallpapers"
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeXs
        }
    }
}