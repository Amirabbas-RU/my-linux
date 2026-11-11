import QtQuick

import "../../theme"

SettingSection {
    id: root

    required property var backend

    title: "Launcher"

    Column {
        width: parent.width
        spacing: Theme.spacing.sm

        SettingRow {
            width: parent.width
            label: "Search provider"
            hint: "Engine used when you type ? in the launcher"
            value: root.backend.provider
        }

        Flow {
            width: parent.width
            spacing: Theme.spacing.sm

            Repeater {
                model: root.backend.providers

                SettingChip {
                    required property string modelData
                    label: modelData
                    active: root.backend.provider === modelData
                    onTriggered: root.backend.setProvider(modelData)
                }
            }
        }
    }

    SettingRow {
        width: parent.width
        label: "Applications"
        hint: "Desktop entries discovered on this system"
        value: root.backend.appsReady ? String(root.backend.appCount) : "\u2026"
    }
}