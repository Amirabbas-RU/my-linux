import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: root.shellState.volumePopupOpen || card.opacity > 0.002
    focusable: root.shellState.volumePopupOpen
    WlrLayershell.namespace: "mylinux-volume"
    WlrLayershell.layer: WlrLayer.Overlay

    property int tick: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var outputs: {
        void(root.tick)
        const list = Pipewire.nodes ? Pipewire.nodes.values : []
        const out = []
        if (!list) return out
        for (let i = 0; i < list.length; i++) {
            const n = list[i]
            if (n && n.isSink && !n.isStream && n.audio) out.push(n)
        }
        return out
    }
    readonly property var inputs: {
        void(root.tick)
        const list = Pipewire.nodes ? Pipewire.nodes.values : []
        const out = []
        if (!list) return out
        for (let i = 0; i < list.length; i++) {
            const n = list[i]
            if (n && !n.isSink && !n.isStream && n.audio) out.push(n)
        }
        return out
    }
    readonly property var streams: {
        void(root.tick)
        const list = Pipewire.nodes ? Pipewire.nodes.values : []
        const out = []
        if (!list) return out
        for (let i = 0; i < list.length; i++) {
            const n = list[i]
            if (n && n.isStream && n.audio) out.push(n)
        }
        return out
    }

    function close() {
        root.shellState.volumePopupOpen = false
    }

    function nodeLabel(n) {
        if (!n) return ""
        if (n.description && n.description.length > 0) return n.description
        if (n.nickname && n.nickname.length > 0) return n.nickname
        return n.name || "Device"
    }

    function streamLabel(n) {
        if (!n) return ""
        const p = n.properties || {}
        const app = p["application.name"] || p["application.process.binary"] || ""
        return app.length > 0 ? app : root.nodeLabel(n)
    }

    onVisibleChanged: if (root.visible) root.tick++

    Timer {
        interval: 1500
        repeat: true
        running: root.visible
        onTriggered: root.tick++
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.28)
            opacity: root.shellState.volumePopupOpen ? 1 : 0
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
            id: card
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Theme.barHeight + Theme.spacing.sm
            anchors.rightMargin: Theme.barMargin
            width: 360
            height: Math.min(
                parent.height - (Theme.barHeight + Theme.spacing.sm) - Theme.spacing.lg,
                body.implicitHeight + Theme.spacing.xl * 2)
            radius: Theme.radius.lg
            color: Theme.color.surface
            border.width: 1
            border.color: Theme.color.borderDim

            opacity: root.shellState.volumePopupOpen ? 1.0 : 0.0
            scale: root.shellState.volumePopupOpen ? 1.0 : 0.96
            transformOrigin: Item.TopRight

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

            MouseArea { anchors.fill: parent }

            Flickable {
                anchors.fill: parent
                anchors.margins: Theme.spacing.xl
                contentWidth: width
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: body
                    width: parent.width
                    spacing: Theme.spacing.lg

                    Item {
                        width: parent.width
                        height: 24

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacing.sm

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.sink && root.sink.audio && root.sink.audio.muted) ? "\u{f0581}" : "\u{f057e}"
                                color: Theme.color.text
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeLg
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Sound"
                                color: Theme.color.text
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeMd
                                font.weight: Theme.font.weightBold
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 22
                            radius: Theme.radius.sm
                            color: masterHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent
                            border.width: 1
                            border.color: Theme.color.borderDim

                            Text {
                                anchors.centerIn: parent
                                text: (root.sink && root.sink.audio && root.sink.audio.muted) ? "\u{f0581}" : "\u{f057e}"
                                color: (root.sink && root.sink.audio && root.sink.audio.muted) ? Theme.color.primary : Theme.color.textMuted
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeSm
                            }

                            HoverHandler { id: masterHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                                }
                            }
                        }
                    }

                    SectionLabel { text: "OUTPUT" }

                    DeviceRow {
                        width: parent.width
                        node: root.sink
                        primary: true
                    }

                    Repeater {
                        model: root.outputs

                        DeviceRow {
                            required property var modelData
                            width: body.width
                            node: modelData
                            selected: root.sink === modelData
                            onPicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }

                    SectionLabel { text: "INPUT" }

                    DeviceRow {
                        width: parent.width
                        node: root.source
                        primary: true
                    }

                    Repeater {
                        model: root.inputs

                        DeviceRow {
                            required property var modelData
                            width: body.width
                            node: modelData
                            selected: root.source === modelData
                            onPicked: Pipewire.preferredDefaultAudioSource = modelData
                        }
                    }

                    SectionLabel {
                        text: "APPLICATIONS"
                        visible: root.streams.length > 0
                    }

                    Repeater {
                        model: root.streams

                        StreamRow {
                            required property var modelData
                            width: body.width
                            node: modelData
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.sink === null && root.outputs.length === 0
                        text: "No audio devices available"
                        color: Theme.color.textFaint
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeSm
                    }
                }
            }
        }
    }

    component SectionLabel: Text {
        width: parent ? parent.width : 0
        color: Theme.color.textFaint
        font.family: Theme.font.mono
        font.pixelSize: Theme.font.sizeXs
        font.letterSpacing: 1.4
    }

    component Level: Item {
        id: lvl
        property real value: 0
        signal moved(real v)
        implicitHeight: 22

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.color.surfaceAlt

            Rectangle {
                width: Math.max(0, Math.min(track.width, lvl.value * track.width))
                height: parent.height
                radius: parent.radius
                color: Theme.color.primary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function applyAt(px) {
                const ratio = Math.max(0, Math.min(1, px / Math.max(1, lvl.width)))
                lvl.moved(ratio)
            }

            onPressed: (m) => applyAt(m.x)
            onPositionChanged: (m) => { if (pressed) applyAt(m.x) }
        }
    }

    component MuteButton: Rectangle {
        id: btn
        property bool muted: false
        signal triggered()
        implicitWidth: 32
        implicitHeight: 22
        radius: Theme.radius.sm
        color: btnHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent
        border.width: 1
        border.color: Theme.color.borderDim

        Text {
            anchors.centerIn: parent
            text: btn.muted ? "\u{f0581}" : "\u{f057e}"
            color: btn.muted ? Theme.color.primary : Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.sizeSm
        }

        HoverHandler { id: btnHover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.triggered()
        }
    }

    component DeviceRow: Item {
        id: row
        property var node: null
        property bool selected: false
        property bool primary: false
        signal picked()
        implicitHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: Theme.spacing.xs

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 72
                    text: root.nodeLabel(row.node)
                    color: row.selected ? Theme.color.text : Theme.color.textDim
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeXs
                    elide: Text.ElideRight
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.selected ? "DEFAULT" : ""
                    color: Theme.color.primary
                    font.family: Theme.font.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.0
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 72
                    enabled: !row.primary
                    cursorShape: row.primary ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: row.picked()
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacing.sm

                Level {
                    width: parent.width - 40
                    value: row.node && row.node.audio ? row.node.audio.volume : 0
                    onMoved: (v) => {
                        if (row.node && row.node.audio) row.node.audio.volume = v
                    }
                }

                MuteButton {
                    muted: row.node && row.node.audio ? row.node.audio.muted : false
                    onTriggered: {
                        if (row.node && row.node.audio) row.node.audio.muted = !row.node.audio.muted
                    }
                }
            }
        }
    }

    component StreamRow: Item {
        id: row
        property var node: null
        implicitHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: Theme.spacing.xs

            Text {
                width: parent.width
                text: root.streamLabel(row.node)
                color: Theme.color.textDim
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeXs
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                spacing: Theme.spacing.sm

                Level {
                    width: parent.width - 40
                    value: row.node && row.node.audio ? row.node.audio.volume : 0
                    onMoved: (v) => {
                        if (row.node && row.node.audio) row.node.audio.volume = v
                    }
                }

                MuteButton {
                    muted: row.node && row.node.audio ? row.node.audio.muted : false
                    onTriggered: {
                        if (row.node && row.node.audio) row.node.audio.muted = !row.node.audio.muted
                    }
                }
            }
        }
    }
}
