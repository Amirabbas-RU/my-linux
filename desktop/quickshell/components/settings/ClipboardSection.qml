import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"

SettingSection {
    id: root

    required property var backend

    title: "Clipboard"

    SettingRow {
        width: parent.width
        label: "History"
        hint: root.backend.clipboardAvailable
            ? (root.backend.clipboardEntries.length > 0
                ? "Entries stored by cliphist"
                : "Nothing copied yet")
            : "cliphist is not available on this system"
        value: root.backend.clipboardAvailable ? String(root.backend.clipboardEntries.length) : "\u2014"
    }

    Row {
        spacing: Theme.spacing.sm

        SettingButton {
            label: "Refresh"
            glyph: "\u{f0450}"
            onTriggered: root.backend.reloadClipboard()
        }

        SettingButton {
            label: "Clear history"
            glyph: "\u{f0ce4}"
            danger: true
            enabled: root.backend.clipboardAvailable && root.backend.clipboardEntries.length > 0
            opacity: enabled ? 1.0 : 0.45
            onTriggered: root.backend.clearClipboard()
        }
    }
}