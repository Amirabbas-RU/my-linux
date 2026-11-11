import QtQuick

import "../../theme"

SettingSection {
    id: root

    required property var backend

    title: "About"

    Column {
        width: parent.width
        spacing: Theme.spacing.sm

        SettingRow { width: parent.width; label: "Distribution"; value: "MyLinux" }

        SettingRow {
            width: parent.width
            label: "Hostname"
            value: root.backend.hostname.length > 0 ? root.backend.hostname : "\u2026"
        }

        SettingRow {
            width: parent.width
            label: "Kernel"
            value: root.backend.kernel.length > 0 ? root.backend.kernel : "\u2026"
        }

        SettingRow {
            width: parent.width
            label: "Session"
            value: root.backend.sessionType + " \u00b7 " + root.backend.compositor
        }

        SettingRow {
            width: parent.width
            label: "Shell"
            value: "Quickshell \u00b7 " + Theme.font.family
        }
    }
}