import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: root.shellState.launcherOpen
    focusable: root.shellState.launcherOpen
    WlrLayershell.namespace: "mylinux-launcher"
    WlrLayershell.layer: WlrLayer.Overlay

    function close(): void {
        root.shellState.launcherOpen = false
        searchField.text = ""
    }

    function activate(execString): void {
        if (!execString) return
        Quickshell.execDetached(["sh", "-c", execString])
        close()
    }

    ListModel { id: appsModel }

    Component.onCompleted: root.reload()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.reload() }
    }

    Connections {
        target: root.shellState
        function onLauncherOpenChanged() {
            if (root.shellState.launcherOpen) {
                root.reload()
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
    }

    function reload(): void {
        appsModel.clear()
        const apps = DesktopEntries.applications
        const items = apps ? (apps.values ? apps.values : []) : []
        for (let i = 0; i < items.length; i++) {
            const app = items[i]
            if (app.noDisplay) continue
            appsModel.append({
                name: app.name || app.id,
                exec: app.execString || "",
                icon: app.icon || "",
                matched: true
            })
        }
    }

    function filter(): void {
        const needle = searchField.text.toLowerCase()
        for (let i = 0; i < appsModel.count; i++) {
            const item = appsModel.get(i)
            appsModel.setProperty(i, "matched", needle === "" || item.name.toLowerCase().indexOf(needle) !== -1)
        }
    }

    function launchFirstMatch(): void {
        for (let i = 0; i < appsModel.count; i++) {
            const item = appsModel.get(i)
            if (item.matched) {
                root.activate(item.exec)
                return
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.topMargin: 120
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 120, 620)
        height: Math.min(parent.height - 240, 440)
        radius: Theme.radius.lg
        color: Qt.rgba(0x13 / 255, 0x17 / 255, 0x22 / 255, 0.98)
        border.color: Theme.color.border
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacing.lg
            spacing: Theme.spacing.md

            Rectangle {
                id: searchBox
                width: parent.width
                height: 44
                radius: Theme.radius.md
                color: Theme.color.surfaceAlt
                border.color: searchField.activeFocus ? Theme.color.primary : Theme.color.border
                border.width: 1

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search applications"
                    color: Theme.color.textMuted
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeMd
                    visible: searchField.text.length === 0
                }

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.md
                    anchors.rightMargin: Theme.spacing.md
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeMd
                    onTextChanged: root.filter()
                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.launchFirstMatch()
                    Keys.onDownPressed: appsFilter.incrementCurrentIndex()
                    Keys.onUpPressed: appsFilter.decrementCurrentIndex()
                }
            }

            ListView {
                id: appsFilter
                width: parent.width
                height: parent.height - searchBox.height - Theme.spacing.md
                clip: true
                spacing: Theme.spacing.xxs
                model: appsModel
                currentIndex: -1

                delegate: Item {
                    id: entry
                    required property string name
                    required property string exec
                    required property string icon
                    required property bool matched

                    width: appsFilter.width
                    height: matched ? 44 : 0
                    visible: matched

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius.md
                        color: (entryHover.hovered || ListView.isCurrentItem && appsFilter.currentIndex >= 0)
                            ? Theme.color.surfaceAlt
                            : Theme.color.transparent

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacing.md
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacing.md

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                source: entry.icon !== "" ? Quickshell.iconPath(entry.icon, true) : ""
                                sourceSize.width: 20
                                sourceSize.height: 20
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.name
                                color: Theme.color.text
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeMd
                            }
                        }

                        HoverHandler { id: entryHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activate(entry.exec)
                        }
                    }
                }
            }
        }
    }
}
