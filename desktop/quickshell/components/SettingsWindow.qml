import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

import "../theme"
import "settings"

PanelWindow {
    id: root
    required property ShellState shellState
    required property var backend

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: root.shellState.settingsOpen || window.opacity > 0.002
    focusable: root.shellState.settingsOpen
    WlrLayershell.namespace: "mylinux-settings"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property var pages: [
        { id: "appearance", label: "Appearance", hint: "Panel and shape" },
        { id: "launcher", label: "Launcher", hint: "Search and apps" },
        { id: "clipboard", label: "Clipboard", hint: "History" },
        { id: "about", label: "About", hint: "System" }
    ]

    property int pageIndex: 0
    readonly property string page: root.pages[root.pageIndex].id

    function pageIndexFor(id): int {
        for (let i = 0; i < root.pages.length; i++) {
            if (root.pages[i].id === id) return i
        }
        return 0
    }

    onVisibleChanged: {
        if (root.visible) root.pageIndex = root.pageIndexFor(root.shellState.settingsPage)
    }

    function close(): void {
        root.shellState.settingsOpen = false
    }

    function movePage(delta): void {
        let next = root.pageIndex + delta
        if (next < 0) next = root.pages.length - 1
        if (next >= root.pages.length) next = 0
        root.pageIndex = next
        root.shellState.settingsPage = root.pages[next].id
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.close()
        Keys.onDownPressed: root.movePage(1)
        Keys.onUpPressed: root.movePage(-1)

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: root.shellState.settingsOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                    easing.type: Theme.motion.easeOut
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: window
            anchors.centerIn: parent
            width: Math.min(parent.width - 140, 780)
            height: Math.min(parent.height - 120, 560)
            radius: Theme.radius.xl
            color: Theme.color.surface
            border.width: 1
            border.color: Theme.color.borderDim
            clip: true

            opacity: root.shellState.settingsOpen ? 1.0 : 0.0
            scale: root.shellState.settingsOpen ? 1.0 : 0.98
            Behavior on opacity {
                NumberAnimation {
                    duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                    easing.type: Theme.motion.easeOut
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: root.shellState.reducedMotion ? 0 : Theme.motion.normal
                    easing.type: Theme.motion.easeOut
                }
            }

            GrainOverlay {
                anchors.fill: parent
                radius: window.radius
                strength: 0.05
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.width: 1
                border.color: Theme.color.borderStrong
                opacity: 0.4
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Row {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    id: sidebar
                    width: 208
                    height: parent.height
                    color: Theme.color.base
                    border.width: 0

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 1
                        color: Theme.color.borderDim
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.lg
                        spacing: Theme.spacing.lg

                        Column {
                            width: parent.width
                            spacing: 2

                            Text {
                                text: "MyLinux"
                                color: Theme.color.text
                                font.family: Theme.font.pixel
                                font.pixelSize: Theme.font.sizeLg
                            }

                            Text {
                                text: "SETTINGS"
                                color: Theme.color.textFaint
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.sizeXs
                                font.letterSpacing: 2.0
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: Theme.color.borderDim }

                        Column {
                            width: parent.width
                            spacing: Theme.spacing.xxs

                            Repeater {
                                model: root.pages

                                Rectangle {
                                    id: navItem
                                    required property var modelData
                                    required property int index

                                    width: parent.width
                                    height: 46
                                    radius: Theme.radius.sm
                                    color: root.pageIndex === index
                                        ? Theme.color.surfaceAlt
                                        : (navHover.hovered ? Theme.color.surface : "transparent")
                                    border.width: 1
                                    border.color: root.pageIndex === index
                                        ? Theme.color.borderDim
                                        : "transparent"

                                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                                    Rectangle {
                                        visible: root.pageIndex === navItem.index
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 2
                                        height: 18
                                        color: Theme.color.primary
                                    }

                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.spacing.md
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            text: navItem.modelData.label
                                            color: root.pageIndex === navItem.index
                                                ? Theme.color.text : Theme.color.textMuted
                                            font.family: Theme.font.family
                                            font.pixelSize: Theme.font.sizeSm
                                            font.weight: Theme.font.weightMedium
                                        }

                                        Text {
                                            text: navItem.modelData.hint.toUpperCase()
                                            color: Theme.color.textFaint
                                            font.family: Theme.font.mono
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.6
                                        }
                                    }

                                    HoverHandler { id: navHover }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.pageIndex = navItem.index
                                            root.shellState.settingsPage = navItem.modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 1 }

                        Text {
                            width: parent.width
                            text: "SUPER + ,"
                            color: Theme.color.textFaint
                            font.family: Theme.font.mono
                            font.pixelSize: 10
                            font.letterSpacing: 1.0
                        }
                    }
                }

                Item {
                    id: pane
                    width: parent.width - sidebar.width
                    height: parent.height

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.xl
                        contentWidth: width
                        contentHeight: stack.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        Column {
                            id: stack
                            width: parent.width
                            spacing: Theme.spacing.xl

                            AppearanceSection {
                                width: parent.width
                                visible: root.page === "appearance"
                            }

                            LauncherSection {
                                width: parent.width
                                visible: root.page === "launcher"
                                backend: root.backend
                            }

                            ClipboardSection {
                                width: parent.width
                                visible: root.page === "clipboard"
                                backend: root.backend
                            }

                            AboutSection {
                                width: parent.width
                                visible: root.page === "about"
                                backend: root.backend
                            }
                        }
                    }
                }
            }
        }
    }
}