import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Application launcher overlay.
//
// Rendered as a full-screen dimmed overlay so it works reliably under
// wlr-layer-shell without needing top-level popup support. Lists desktop
// entries discovered by Quickshell's DesktopEntries singleton and launches
// the selected entry detached from the shell.
PanelWindow {
    id: launcher
    required property ShellState shellState

    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    focusable: shellState.launcherOpen
    visible: shellState.launcherOpen

    function toggle(): void {
        const open = !shellState.launcherOpen
        shellState.closeAll()
        shellState.launcherOpen = open
        if (open) loadModel()
    }
    function close(): void { shellState.launcherOpen = false }

    function loadModel(): void {
        appsModel.clear()
        const apps = DesktopEntries.applications
        const items = apps ? apps.values : []
        for (let i = 0; i < items.length; i++) {
            const app = items[i]
            if (app.noDisplay) continue
            appsModel.append({
                name: app.name || app.id,
                exec: app.execString || "",
                icon: app.icon || ""
            })
        }
    }

    function activate(execString): void {
        if (!execString) return
        Quickshell.execDetached(["sh", "-c", execString])
        close()
    }

    // Dim backdrop; click outside to close.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        TapHandler { onTapped: launcher.close() }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 620)
        height: Math.min(parent.height - 120, 460)
        radius: Theme.radius.lg
        color: Theme.color.surface
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
                    text: "Search applications\u2026"
                    color: Theme.color.textMuted
                    font.family: Theme.font.uiFamily
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
                    font.family: Theme.font.uiFamily
                    font.pixelSize: Theme.font.sizeMd
                    focus: launcher.shellState.launcherOpen
                    onTextChanged: appsFilter.text = text
                    Keys.onEscapePressed: launcher.close()
                    Keys.onReturnPressed: {
                        if (filtered.count > 0) launcher.activate(filtered.itemAt(0).exec)
                    }
                }
            }

            ListView {
                id: filtered
                width: parent.width
                height: parent.height - searchBox.height - Theme.spacing.md
                clip: true
                spacing: Theme.spacing.xs
                model: appsModel
                property string text: ""

                delegate: Rectangle {
                    required property string name
                    required property string exec
                    required property string icon
                    width: filtered.width
                    height: 44
                    radius: Theme.radius.md
                    color: itemHover.hovered ? Theme.color.surfaceHi : Theme.color.transparent
                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.md

                        Image {
                            width: 20; height: 20
                            source: parent.parent.icon !== "" ? Quickshell.iconPath(parent.parent.icon, true) : ""
                            sourceSize.width: 20; sourceSize.height: 20
                            visible: status === Image.Ready
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: parent.parent.name
                            color: Theme.color.text
                            font.family: Theme.font.uiFamily
                            font.pixelSize: Theme.font.sizeMd
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    HoverHandler { id: itemHover }
                    TapHandler { onTapped: launcher.activate(parent.exec) }
                }
            }
        }
    }

    ListModel { id: appsModel }
}
