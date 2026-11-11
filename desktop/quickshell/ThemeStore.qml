import QtQuick
import Quickshell
import Quickshell.Io

import "theme"

Item {
    id: store

    visible: false
    width: 0
    height: 0

    FileView {
        id: file
        path: Theme.stateFile
        watchChanges: false
        atomicWrites: true
        onLoaded: Theme.applyState(text())
        onLoadFailed: Theme.stateLoaded = true
        onSaveFailed: Theme.lastError = "Could not save theme settings"
    }

    function save() {
        if (!Theme.stateLoaded) return
        file.setText(JSON.stringify({
            barHeight: Theme.barHeight,
            barMargin: Theme.barMargin,
            barTopMargin: Theme.barTopMargin,
            radius: Theme.radius.md
        }))
    }

    Connections {
        target: Theme
        function onSaveRequested() { store.save() }
    }
}