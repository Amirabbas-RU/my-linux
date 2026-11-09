import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../theme"
import "../logic/Modes.js" as Modes
import "../logic/Calc.js" as Calc
import "launcher"

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

    readonly property var modes: Modes.all()
    readonly property var providers: Modes.providers()

    property string inputText: ""
    property string activeMode: "apps"
    property bool explicitMode: false
    property string query: ""
    property int selectedIndex: 0
    property var results: []
    property string toast: ""

    property var calcResult: null

    LauncherBackend {
        id: backend
    }

    function close(): void {
        root.shellState.launcherOpen = false
        root.shellState.launcherQuery = ""
        root.inputText = ""
    }

    function refresh(): void {
        const parsed = Modes.parse(root.inputText)
        root.activeMode = parsed.mode
        root.explicitMode = parsed.explicit
        root.query = parsed.query

        if (root.activeMode === "apps") {
            root.results = backend.rankApps(root.query)
        } else {
            root.results = []
            if (root.activeMode === "calc") {
                root.calcResult = root.query.length > 0 ? Calc.compute(root.query) : null
            } else if (root.activeMode === "wall") {
                backend.reloadCurrentWallpaper()
            } else if (root.activeMode === "clip") {
                backend.reloadClipboard()
            }
        }
        root.selectedIndex = 0
        if (root.activeMode === "session" && root.query.length > 0) {
            const q = root.query.toLowerCase()
            for (let i = 0; i < sessionView.actions.length; i++) {
                const a = sessionView.actions[i]
                if (a.id.toLowerCase().indexOf(q) !== -1 || a.label.toLowerCase().indexOf(q) !== -1) {
                    root.selectedIndex = i
                    break
                }
            }
        }
    }

    function modeCount(): int {
        if (root.activeMode === "apps") return root.results.length
        if (root.activeMode === "wall") return backend.wallpapers.length
        if (root.activeMode === "clip") return clipView.filtered().length
        if (root.activeMode === "session") return sessionView.actions.length
        return 0
    }

    function moveSelection(delta): void {
        const count = root.modeCount()
        if (count === 0) return
        let next = root.selectedIndex + delta
        if (next < 0) next = count - 1
        if (next >= count) next = 0
        root.selectedIndex = next
        if (root.activeMode === "apps") resultList.positionViewAtIndex(next, ListView.Contain)
        if (root.activeMode === "wall") wallView.positionTo(next)
        if (root.activeMode === "clip") clipView.positionTo(next)
    }

    function activateCurrent(): void {
        if (root.activeMode === "apps") {
            if (root.selectedIndex < root.results.length) root.launch(root.results[root.selectedIndex])
        } else if (root.activeMode === "calc") {
            root.copyCalc()
        } else if (root.activeMode === "web") {
            root.openWeb()
        } else if (root.activeMode === "wall") {
            if (root.selectedIndex < backend.wallpapers.length) root.applyWallpaper(backend.wallpapers[root.selectedIndex].path)
        } else if (root.activeMode === "clip") {
            const entries = clipView.filtered()
            if (root.selectedIndex < entries.length) {
                backend.copyClipboardEntry(entries[root.selectedIndex].id)
                root.flash("Copied to clipboard")
            }
        } else if (root.activeMode === "session") {
            if (sessionView.confirmAction.length > 0) sessionView.confirm()
            else if (sessionView.actions[root.selectedIndex]) sessionView.request(sessionView.actions[root.selectedIndex].id)
        }
    }

    function launch(descriptor): void {
        backend.launchApp(descriptor)
        close()
    }

    function copyCalc(): void {
        if (!root.calcResult || !root.calcResult.ok) return
        backend.copyText(root.calcResult.text)
        root.flash("Copied " + root.calcResult.text)
    }

    function openWeb(): void {
        const q = root.query.trim()
        if (q.length === 0) return
        backend.openUrl(Modes.buildUrl(q, backend.provider))
        close()
    }

    function applyWallpaper(path): void {
        backend.applyWallpaper(path)
        root.flash("Wallpaper applied")
    }

    function flash(message): void {
        root.toast = message
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 1800
        onTriggered: root.toast = ""
    }

    Connections {
        target: root.shellState
        function onLauncherOpenChanged() {
            if (root.shellState.launcherOpen) {
                root.inputText = root.shellState.launcherQuery
                searchField.text = root.shellState.launcherQuery
                root.toast = ""
                root.selectedIndex = 0
                root.refresh()
                searchField.forceActiveFocus()
                if (searchField.text.length > 0) searchField.cursorPosition = searchField.text.length
            }
        }
        function onLauncherModeChanged() {
            if (root.shellState.launcherOpen) root.refresh()
        }
        function onLauncherQueryChanged() {
            if (!root.shellState.launcherOpen) return
            if (searchField.text === root.shellState.launcherQuery) return
            searchField.text = root.shellState.launcherQuery
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            backend.reloadApplications()
            if (root.activeMode === "apps") root.refresh()
        }
    }

    Connections {
        target: backend
        function onWallpapersChanged() {
            if (root.activeMode === "wall") root.selectedIndex = 0
        }
        function onClipboardEntriesChanged() {
            if (root.activeMode === "clip") root.selectedIndex = 0
        }
        function onLastErrorChanged() {
            if (backend.lastError.length > 0) root.flash(backend.lastError)
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
        anchors.topMargin: Math.max(72, Math.round(parent.height * 0.12))
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 120, 680)
        height: Math.min(parent.height * 0.76, 520)
        radius: Theme.radius.xl
        color: Qt.rgba(0x13 / 255, 0x17 / 255, 0x22 / 255, 0.98)
        border.color: Theme.color.border
        border.width: 1
        opacity: root.shellState.launcherOpen ? 1.0 : 0.0
        scale: root.shellState.launcherOpen ? 1.0 : 0.97

        Behavior on opacity { NumberAnimation { duration: Theme.motion.normal; easing.type: Theme.motion.easeOut } }
        Behavior on scale { NumberAnimation { duration: Theme.motion.normal; easing.type: Theme.motion.easeOut } }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacing.lg
            spacing: Theme.spacing.md

            Rectangle {
                id: searchBox
                width: parent.width
                height: 52
                radius: Theme.radius.md
                color: Theme.color.surfaceAlt
                border.color: searchField.activeFocus ? Theme.color.primary : Theme.color.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

                Text {
                    id: hintText
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.md
                    anchors.right: modeChip.left
                    anchors.rightMargin: Theme.spacing.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: Modes.modeHint(root.activeMode)
                    color: Theme.color.textMuted
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeBase
                    elide: Text.ElideRight
                    visible: searchField.text.length === 0
                }

                Rectangle {
                    id: modeChip
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing.sm
                    anchors.verticalCenter: parent.verticalCenter
                    width: chipLabel.implicitWidth + Theme.spacing.md * 2
                    height: 26
                    radius: Theme.radius.pill
                    color: root.activeMode === "apps" && !root.explicitMode
                        ? Theme.color.surface : Theme.color.primary
                    border.width: 1
                    border.color: root.activeMode === "apps" && !root.explicitMode
                        ? Theme.color.border : Theme.color.primary

                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: root.activeMode === "apps" && !root.explicitMode
                            ? "Applications" : Modes.modeLabel(root.activeMode)
                        color: root.activeMode === "apps" && !root.explicitMode
                            ? Theme.color.textDim : Theme.color.base
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeXs
                        font.weight: Theme.font.weightMedium
                    }
                }

                TextInput {
                    id: searchField
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.md
                    anchors.right: modeChip.left
                    anchors.rightMargin: Theme.spacing.sm
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.color.text
                    selectionColor: Theme.color.primary
                    selectedTextColor: Theme.color.base
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeLg
                    clip: true
                    onTextChanged: {
                        root.inputText = text
                        root.refresh()
                    }
                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.activateCurrent()
                    Keys.onEnterPressed: root.activateCurrent()
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onUpPressed: root.moveSelection(-1)
                }
            }

            Item {
                id: body
                width: parent.width
                height: parent.height - searchBox.height - footer.height - Theme.spacing.md * 2

                ListView {
                    id: resultList
                    anchors.fill: parent
                    visible: root.activeMode === "apps"
                    clip: true
                    spacing: Theme.spacing.xxs
                    model: root.results
                    currentIndex: root.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: AppRow {
                        required property int index
                        required property var modelData
                        width: resultList.width
                        descriptor: modelData
                        active: index === root.selectedIndex
                        onActivated: root.launch(modelData)
                        onToggledFavorite: {
                            backend.toggleFavorite(modelData.id)
                            root.refresh()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.results.length === 0
                        text: backend.appsReady
                            ? (root.query.length > 0 ? "No applications match \u201c" + root.query + "\u201d" : "No applications found")
                            : "Loading applications\u2026"
                        color: Theme.color.textMuted
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeMd
                    }
                }

                CalcView {
                    anchors.fill: parent
                    visible: root.activeMode === "calc"
                    expression: root.query
                    result: root.calcResult
                    onCopyRequested: root.copyCalc()
                }

                WebView {
                    anchors.fill: parent
                    visible: root.activeMode === "web"
                    provider: backend.provider
                    providers: root.providers
                    query: root.query
                    onProviderSelected: function (name) {
                        backend.setProvider(name)
                        root.flash("Search provider: " + name)
                    }
                    onOpenRequested: root.openWeb()
                }

                WallpaperView {
                    id: wallView
                    anchors.fill: parent
                    visible: root.activeMode === "wall"
                    wallpapers: backend.wallpapers
                    currentPath: backend.currentWallpaper
                    backendMissing: backend.wallpaperBackendMissing
                    selectedIndex: root.selectedIndex
                    onSelected: function (path) { root.applyWallpaper(path) }
                }

                ClipboardView {
                    id: clipView
                    anchors.fill: parent
                    visible: root.activeMode === "clip"
                    entries: backend.clipboardEntries
                    available: backend.clipboardAvailable
                    query: root.query
                    selectedIndex: root.selectedIndex
                    onCopyRequested: function (id) {
                        backend.copyClipboardEntry(id)
                        root.flash("Copied to clipboard")
                    }
                    onClearRequested: {
                        backend.clearClipboard()
                        root.flash("Clipboard history cleared")
                    }
                }

                SessionView {
                    id: sessionView
                    anchors.fill: parent
                    visible: root.activeMode === "session"
                    selectedIndex: root.selectedIndex
                    onActionRequested: function (action) {
                        backend.runSessionAction(action)
                        root.close()
                    }
                }
            }

            Rectangle {
                id: footer
                width: parent.width
                height: 28
                color: Theme.color.transparent

                Text {
                    id: footerHint
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.toast.length > 0 ? root.toast : "\u21b5 select    \u2191\u2193 move    esc close"
                    color: root.toast.length > 0 ? Theme.color.success : Theme.color.textMuted
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeXs
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: footerHint.left
                    anchors.rightMargin: Theme.spacing.lg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.md
                    clip: true

                    Repeater {
                        model: root.modes

                        Row {
                            required property var modelData
                            spacing: Theme.spacing.xxs

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.prefix
                                color: root.activeMode === modelData.id ? Theme.color.primary : Theme.color.textDim
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.sizeXs
                                font.weight: Theme.font.weightBold
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.short
                                color: root.activeMode === modelData.id ? Theme.color.text : Theme.color.textMuted
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeXs
                            }
                        }
                    }
                }
            }
        }
    }
}