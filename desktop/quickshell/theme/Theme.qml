pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject color: QtObject {
        readonly property color base:        "#000000"
        readonly property color surface:     "#0a0a0a"
        readonly property color surfaceAlt:  "#161310"
        readonly property color border:      "#cdc4ba"
        readonly property color borderDim:   "#cdc4ba0f"
        readonly property color borderStrong: "#cdc4ba3d"
        readonly property color text:        "#cdc4ba"
        readonly property color textDim:     "#b0a9a0"
        readonly property color textMuted:   "#958f87"
        readonly property color textFaint:   "#7a756e"

        readonly property color primary:     "#ce5e32"
        readonly property color primaryDim:  "#ce5e32"
        readonly property color accent:      "#cdc4ba"
        readonly property color accentDim:   "#b0a9a0"

        readonly property color success:     "#b0a9a0"
        readonly property color warning:     "#ce5e32"
        readonly property color danger:      "#ce5e32"

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
        readonly property string family:   "Geist"
        readonly property string mono:     "Geist Mono"
        readonly property string fallback: "Geist"
        readonly property string pixel:    "Geist Pixel Square"
        readonly property string persian:  "Vazirmatn"

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
