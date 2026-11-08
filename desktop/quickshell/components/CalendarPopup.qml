import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Calendar popup shown when the clock is clicked.
PanelWindow {
    id: calendarPopup
    required property ShellState shellState

    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.color.transparent
    exclusiveZone: 0
    visible: shellState.calendarOpen
    focusable: shellState.calendarOpen

    property string monthText: ""
    property var days: []

    function toggle(): void {
        const open = !shellState.calendarOpen
        shellState.closeAll()
        shellState.calendarOpen = open
    }
    function close(): void { shellState.calendarOpen = false }

    Process {
        id: calProc
        command: ["sh", "-c", "date '+%B %Y'; cal"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                calendarPopup.monthText = lines[0]
                calendarPopup.days = lines.slice(1)
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: calProc.running = true }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        TapHandler { onTapped: calendarPopup.close() }
    }

    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.spacing.md
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320
        height: calColumn.implicitHeight + Theme.spacing.xl * 2
        radius: Theme.radius.lg
        color: Theme.color.surface
        border.color: Theme.color.border
        border.width: 1

        Column {
            id: calColumn
            anchors.centerIn: parent
            spacing: Theme.spacing.sm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: calendarPopup.monthText
                color: Theme.color.primary
                font.family: Theme.font.uiFamily
                font.pixelSize: Theme.font.sizeLg
                font.weight: Theme.font.weightBold
            }
            Repeater {
                model: calendarPopup.days
                Text {
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.sizeSm
                }
            }
        }
    }
}
