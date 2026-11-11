import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland

import "../theme"

PanelWindow {
    id: root
    required property ShellState shellState

    anchors { top: true; left: true; right: true; bottom: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: root.shellState.networkPopupOpen || card.opacity > 0.002
    focusable: root.shellState.networkPopupOpen
    WlrLayershell.namespace: "mylinux-network"
    WlrLayershell.layer: WlrLayer.Overlay

    property int tick: 0
    property var pending: null
    property string password: ""

    readonly property var wifiDevice: {
        void(root.tick)
        const list = Networking.devices ? Networking.devices.values : []
        if (!list) return null
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].type === DeviceType.Wifi) return list[i]
        }
        return null
    }
    readonly property var wiredDevice: {
        void(root.tick)
        const list = Networking.devices ? Networking.devices.values : []
        if (!list) return null
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].type === DeviceType.Wired) return list[i]
        }
        return null
    }
    readonly property bool wiredUp: root.wiredDevice ? root.wiredDevice.connected : false
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool wifiAvailable: Networking.wifiHardwareEnabled && root.wifiDevice !== null

    readonly property var networks: {
        void(root.tick)
        const device = root.wifiDevice
        if (!device) return []
        const model = device.networks
        const list = model ? (model.values ? model.values : []) : []
        const out = []
        for (let i = 0; i < list.length; i++) {
            if (list[i]) out.push(list[i])
        }
        out.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.known !== b.known) return a.known ? -1 : 1
            return (b.signalStrength || 0) - (a.signalStrength || 0)
        })
        return out
    }

    readonly property string summary: {
        if (!root.wifiDevice && !root.wiredDevice) return "No adapter"
        if (root.wiredUp) return "Wired connection"
        if (!root.wifiOn) return "Wi-Fi off"
        for (let i = 0; i < root.networks.length; i++) {
            if (root.networks[i].connected) return root.networks[i].name || "Connected"
        }
        return root.wifiAvailable ? "Not connected" : "Wi-Fi unavailable"
    }

    function close() {
        root.shellState.networkPopupOpen = false
    }

    function pct(net) {
        if (!net) return 0
        const s = net.signalStrength
        if (typeof s !== "number") return 0
        return Math.max(0, Math.min(100, Math.round(s <= 1 ? s * 100 : s)))
    }

    function openNetwork(net) {
        return net.security === WifiSecurityType.Open || net.security === WifiSecurityType.Owe
    }

    function activate(net) {
        if (!net) return
        if (net.connected) {
            net.disconnect()
            return
        }
        if (net.known || root.openNetwork(net)) {
            net.connect()
            return
        }
        root.pending = net
        root.password = ""
        Qt.callLater(function () {
            if (pwField.visible) pwField.forceActiveFocus()
        })
    }

    function submitPassword() {
        if (root.pending && root.password.length > 0) root.pending.connectWithPsk(root.password)
        root.pending = null
        root.password = ""
    }

    onVisibleChanged: {
        if (root.visible) {
            root.tick++
            root.pending = null
            root.password = ""
            if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible
        onTriggered: root.tick++
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: {
            if (root.pending) {
                root.pending = null
                root.password = ""
            } else {
                root.close()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.28)
            opacity: root.shellState.networkPopupOpen ? 1 : 0
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

            opacity: root.shellState.networkPopupOpen ? 1.0 : 0.0
            scale: root.shellState.networkPopupOpen ? 1.0 : 0.96
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

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: Theme.spacing.xl
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
                            text: root.wiredUp ? "\u{f0e8}" : (root.wifiOn ? "\u{f1eb}" : "\u{f05aa}")
                            color: Theme.color.text
                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.sizeLg
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "Network"
                                color: Theme.color.text
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeMd
                                font.weight: Theme.font.weightBold
                            }

                            Text {
                                text: root.summary
                                color: Theme.color.textMuted
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.sizeXs
                            }
                        }
                    }

                    NetworkSwitch {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.wifiOn
                        enabled: root.wifiAvailable
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.color.borderDim }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: Theme.radius.sm
                    color: Theme.color.surfaceAlt
                    border.width: 1
                    border.color: root.wiredUp ? Theme.color.border : Theme.color.borderDim
                    visible: root.wiredDevice !== null

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.sm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{f0e8}"
                            color: root.wiredUp ? Theme.color.text : Theme.color.textMuted
                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.sizeLg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.wiredDevice ? (root.wiredDevice.name || "Ethernet") : "Ethernet"
                            color: Theme.color.text
                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.sizeSm
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.wiredUp ? "Connected" : "Disconnected"
                        color: root.wiredUp ? Theme.color.textDim : Theme.color.textFaint
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.sizeXs
                    }
                }

                Text {
                    width: parent.width
                    visible: root.networks.length > 0
                    text: "WI-FI NETWORKS"
                    color: Theme.color.textFaint
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.sizeXs
                    font.letterSpacing: 1.4
                }

                Flickable {
                    width: parent.width
                    height: Math.min(listing.implicitHeight, 240)
                    visible: root.networks.length > 0
                    contentWidth: width
                    contentHeight: listing.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: listing
                        width: parent.width
                        spacing: Theme.spacing.xxs

                        Repeater {
                            model: root.networks

                            Rectangle {
                                id: netRow
                                required property var modelData
                                width: listing.width
                                height: 42
                                radius: Theme.radius.sm
                                color: netRow.modelData.connected
                                    ? Theme.color.surfaceAlt
                                    : (netHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent)

                                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacing.sm
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacing.sm

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.pct(netRow.modelData) > 66 ? "\u{f1eb}"
                                            : root.pct(netRow.modelData) > 33 ? "\u{f05a9}" : "\u{f05aa}"
                                        color: netRow.modelData.connected ? Theme.color.text : Theme.color.textMuted
                                        font.family: Theme.font.family
                                        font.pixelSize: Theme.font.sizeLg
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Row {
                                            spacing: Theme.spacing.xs

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: netRow.modelData.name || "Hidden"
                                                color: Theme.color.text
                                                font.family: Theme.font.family
                                                font.pixelSize: Theme.font.sizeSm
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: netRow.modelData.known
                                                text: "\u{f023}"
                                                color: Theme.color.textFaint
                                                font.family: Theme.font.family
                                                font.pixelSize: 11
                                            }
                                        }

                                        Text {
                                            text: netRow.modelData.connected
                                                ? "Connected"
                                                : (root.openNetwork(netRow.modelData) ? "Open" : "Secured")
                                            color: Theme.color.textFaint
                                            font.family: Theme.font.mono
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacing.sm
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.pct(netRow.modelData) + "%"
                                    color: Theme.color.textMuted
                                    font.family: Theme.font.mono
                                    font.pixelSize: Theme.font.sizeXs
                                }

                                HoverHandler { id: netHover }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 60
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activate(netRow.modelData)
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: netRow.modelData.known && netRow.modelData.connected
                                    text: "\u{f00d}"
                                    color: forgetHover.hovered ? Theme.color.primary : Theme.color.textFaint
                                    font.family: Theme.font.family
                                    font.pixelSize: Theme.font.sizeSm

                                    HoverHandler { id: forgetHover }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: netRow.modelData.forget()
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: root.networks.length === 0
                    text: root.wifiAvailable ? "No networks found" : "No Wi-Fi adapter available"
                    color: Theme.color.textFaint
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeSm
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacing.sm
                    visible: root.pending !== null

                    Text {
                        width: parent.width
                        text: root.pending ? (root.pending.name || "Network") : ""
                        color: Theme.color.text
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeSm
                        font.weight: Theme.font.weightBold
                    }

                    TextField {
                        id: pwField
                        width: parent.width
                        height: 36
                        echoMode: TextInput.Password
                        placeholderText: "Password"
                        placeholderTextColor: Theme.color.textFaint
                        color: Theme.color.text
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.sizeSm
                        selectByMouse: true
                        padding: Theme.spacing.sm
                        onTextChanged: root.password = text
                        background: Rectangle {
                            radius: Theme.radius.sm
                            color: Theme.color.base
                            border.width: 1
                            border.color: pwField.activeFocus ? Theme.color.primary : Theme.color.borderDim
                        }
                        onAccepted: root.submitPassword()
                    }

                    Row {
                        spacing: Theme.spacing.sm

                        Rectangle {
                            width: 96
                            height: 32
                            radius: Theme.radius.sm
                            color: connectHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent
                            border.width: 1
                            border.color: Theme.color.border

                            Text {
                                anchors.centerIn: parent
                                text: "Connect"
                                color: Theme.color.text
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.sizeXs
                            }

                            HoverHandler { id: connectHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitPassword()
                            }
                        }

                        Rectangle {
                            width: 80
                            height: 32
                            radius: Theme.radius.sm
                            color: cancelHover.hovered ? Theme.color.surfaceAlt : Theme.color.transparent
                            border.width: 1
                            border.color: Theme.color.borderDim

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.color.textMuted
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.sizeXs
                            }

                            HoverHandler { id: cancelHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.pending = null
                                    root.password = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component NetworkSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled()
        implicitWidth: 40
        implicitHeight: 22
        radius: height / 2
        color: sw.checked ? Theme.color.primary : Theme.color.surfaceAlt
        border.width: 1
        border.color: sw.checked ? Theme.color.primary : Theme.color.borderDim
        opacity: sw.enabled ? 1.0 : 0.4

        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? sw.width - width - 3 : 3
            color: sw.checked ? Theme.color.base : Theme.color.textMuted
            Behavior on x { NumberAnimation { duration: Theme.motion.fast; easing.type: Theme.motion.easeOut } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sw.toggled()
        }
    }
}
