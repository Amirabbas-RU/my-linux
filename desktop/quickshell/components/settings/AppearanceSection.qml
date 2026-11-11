import QtQuick

import "../../theme"

SettingSection {
    id: root

    title: "Appearance"

    function commit() { Theme.persist() }

    SettingSlider {
        width: parent.width
        label: "Bar height"
        hint: "Height of the top panel"
        value: Theme.barHeight
        from: Theme.barHeightMin
        to: Theme.barHeightMax
        suffix: " px"
        onMoved: function (v) { Theme.barHeight = v; root.commit() }
    }

    SettingSlider {
        width: parent.width
        label: "Bar margin"
        hint: "Inset from the screen edges"
        value: Theme.barMargin
        from: Theme.barMarginMin
        to: Theme.barMarginMax
        suffix: " px"
        onMoved: function (v) { Theme.barMargin = v; root.commit() }
    }

    SettingSlider {
        width: parent.width
        label: "Corner radius"
        hint: "Roundness of panels and cards"
        value: Theme.radius.md
        from: Theme.radiusMin
        to: Theme.radiusMax
        suffix: " px"
        onMoved: function (v) { Theme.applyRadius(v); root.commit() }
    }

    Row {
        spacing: Theme.spacing.sm

        SettingButton {
            label: "Reset appearance"
            glyph: "\u{f0453}"
            onTriggered: Theme.resetAppearance()
        }
    }
}