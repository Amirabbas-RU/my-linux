pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject color: QtObject {
        readonly property color base:        "#0B0D12"
        readonly property color surface:     "#131722"
        readonly property color surfaceAlt:  "#1B2230"
        readonly property color border:      "#2A3242"

        readonly property color text:        "#F3F5F7"
        readonly property color textDim:     "#A2AAB8"
        readonly property color textMuted:   "#707B8D"

        readonly property color primary:     "#F5A623"
        readonly property color primaryDim:  "#C9861C"
        readonly property color accent:      "#7C6CF0"
        readonly property color accentDim:   "#5A4DC4"

        readonly property color success:     "#4CC38A"
        readonly property color warning:     "#F5A623"
        readonly property color danger:      "#EF647C"

        readonly property color shadow:      "#000000"
        readonly property color transparent: "transparent"
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xxs: 4
        readonly property int xs:  4
        readonly property int sm:  8
        readonly property int md:  12
        readonly property int lg:  16
        readonly property int xl:  24
        readonly property int xxl: 32
        readonly property int xxxl: 48
    }

    readonly property QtObject radius: QtObject {
        readonly property int sm:   6
        readonly property int md:   10
        readonly property int lg:   14
        readonly property int xl:   20
        readonly property int pill: 999
    }

    readonly property QtObject font: QtObject {
        readonly property string family:   "Inter"
        readonly property string mono:     "JetBrains Mono"
        readonly property string fallback: "Noto Sans"

        readonly property int sizeXs:    12
        readonly property int sizeSm:    12
        readonly property int sizeMd:    13
        readonly property int sizeBase:  14
        readonly property int sizeLg:    16
        readonly property int sizeH2:    20
        readonly property int sizeH1:    24
        readonly property int sizeDisplay: 32

        readonly property int weightNormal: Font.Normal
        readonly property int weightMedium: Font.Medium
        readonly property int weightBold:   Font.Bold
    }

    readonly property QtObject motion: QtObject {
        readonly property int fast:       140
        readonly property int normal:     180
        readonly property int slow:       220
        readonly property int easeOut:    Easing.OutCubic
        readonly property int easeInOut:  Easing.InOutQuad
    }

    readonly property int barHeight:    38
    readonly property int barMargin:    10
    readonly property int barTopMargin: 8
    readonly property int iconSize:     16
}