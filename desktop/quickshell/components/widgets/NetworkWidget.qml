import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

// Network status via NetworkManager / nmcli.
Item {
    id: network
    required property ShellState shellState
    implicitWidth: icon.implicitWidth + Theme.spacing.sm * 2
    implicitHeight: Theme.iconSize + Theme.spacing.sm

    Process {
        id: poll
        command: ["sh", "-c", "nmcli -t -f TYPE,NAME,DEVICE c show --active 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                let ssid = ""
                for (const l of lines) {
                    const parts = l.split(":")
                    if (parts[0] === "wifi" && parts[1]) { ssid = parts[1]; break }
                }
                network.shellState.wifiSsid = ssid
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: poll.running = true }

    Text {
        id: icon
        anchors.centerIn: parent
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.sizeMd
        text: network.shellState.wifiSsid !== "" ? "\u{F05AA}" : "\u{F05A9}"
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    ToolTipText {
        visible: hover.hovered
        text: network.shellState.wifiSsid !== "" ? network.shellState.wifiSsid : "disconnected"
    }
    HoverHandler { id: hover }
    TapHandler { onTapped: Quickshell.execDetached(["nm-connection-editor"]) }
}
