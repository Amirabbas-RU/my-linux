pragma Singleton
import QtQuick

// MyLinux design tokens: a single source of truth for colour, spacing,
// radius, motion and typography used across every shell component.
//
// The palette is original to MyLinux: deep indigo surfaces with a warm
// amber accent evoking a sunrise over a terminal, deliberately distinct
// from the palettes shipped by other Wayland shells.
QtObject {
    id: theme

    // ---- colour ------------------------------------------------------
    readonly property QtObject color: QtObject {
        // surfaces, dark-first
        readonly property color base:        "#0d0b14"
        readonly property color surface:     "#16131f"
        readonly property color surfaceAlt:  "#1e1a2b"
        readonly property color surfaceHi:   "#272236"
        readonly property color overlay:     "#302a44"

        // text
        readonly property color text:        "#ece9f5"
        readonly property color textDim:     "#b6afc9"
        readonly property color textMuted:   "#7c7590"

        // brand
        readonly property color primary:     "#f5a623"
        readonly property color primaryDim:  "#c9861c"
        readonly property color accent:      "#7c6cf0"
        readonly property color accentDim:   "#5a4dc4"

        // semantics
        readonly property color success:     "#5cc98a"
        readonly property color warning:     "#f5c542"
        readonly property color danger:      "#ef5f7a"
        readonly property color info:        "#5aa9e6"

        // utility
        readonly property color border:      "#2f2942"
        readonly property color shadow:      "#000000"
        readonly property color transparent: "transparent"
    }

    // ---- spacing -----------------------------------------------------
    readonly property QtObject spacing: QtObject {
        readonly property int xxs: 2
        readonly property int xs:  4
        readonly property int sm:  8
        readonly property int md:  12
        readonly property int lg:  16
        readonly property int xl:  24
        readonly property int xxl: 32
    }

    // ---- radius ------------------------------------------------------
    readonly property QtObject radius: QtObject {
        readonly property int sm: 6
        readonly property int md: 10
        readonly property int lg: 16
        readonly property int xl: 22
        readonly property int pill: 999
    }

    // ---- typography --------------------------------------------------
    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font"
        readonly property string uiFamily: "Noto Sans"
        readonly property int sizeXs: 10
        readonly property int sizeSm: 11
        readonly property int sizeMd: 13
        readonly property int sizeLg: 15
        readonly property int sizeXl: 20
        readonly property int sizeTitle: 28
        readonly property int weightNormal: Font.Normal
        readonly property int weightMedium: Font.Medium
        readonly property int weightBold: Font.Bold
    }

    // ---- motion ------------------------------------------------------
    readonly property QtObject motion: QtObject {
        readonly property int fast:   120
        readonly property int normal: 220
        readonly property int slow:   360
        readonly property int easeOut: Easing.OutCubic
        readonly property int easeInOut: Easing.InOutQuad
    }

    // ---- geometry ----------------------------------------------------
    readonly property int barHeight: 38
    readonly property int barMargin: 8
    readonly property int iconSize: 16
}
