pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    readonly property string stateFile: (Quickshell.env("HOME") || "") + "/.local/state/mylinux/theme.json"

    readonly property QtObject color: QtObject {
        readonly property color base:        "#000000"
        readonly property color surface:     "#0a0a0a"
        readonly property color surfaceAlt:  "#161310"
        readonly property color border:      Qt.rgba(0.804, 0.769, 0.729, 0.10)
        readonly property color borderDim:   Qt.rgba(0.804, 0.769, 0.729, 0.035)
        readonly property color borderStrong: Qt.rgba(0.804, 0.769, 0.729, 0.14)
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
        property int sm:   6
        property int md:   10
        property int lg:   14
        property int xl:   20
        readonly property int pill: 999
    }

    readonly property QtObject font: QtObject {
        readonly property string family:   "Geist"
        readonly property string mono:     "Geist Mono"
        readonly property string fallback: "Geist"
        readonly property string pixel:    "Geist Pixel Square"
        readonly property string persian:  "Vazirmatn"
        readonly property string cjk:      "Noto Sans CJK JP"

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

    property int barHeight:    38
    property int barMargin:    10
    property int barTopMargin: 8
    readonly property int iconSize: 16

    readonly property int barHeightMin: 32
    readonly property int barHeightMax: 56
    readonly property int barMarginMin: 0
    readonly property int barMarginMax: 24
    readonly property int radiusMin: 2
    readonly property int radiusMax: 24

    property bool stateLoaded: false
    property string lastError: ""

    signal saveRequested()

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value))
    }

    function applyRadius(value) {
        const r = theme.clamp(Math.round(value), theme.radiusMin, theme.radiusMax)
        theme.radius.sm = Math.max(2, r - 4)
        theme.radius.md = r
        theme.radius.lg = r + 4
        theme.radius.xl = r + 10
    }

    function applyState(raw) {
        theme.stateLoaded = true
        let data = null
        try {
            data = JSON.parse(raw)
        } catch (e) {
            data = null
        }
        if (!data || typeof data !== "object") return
        if (typeof data.barHeight === "number") {
            theme.barHeight = theme.clamp(Math.round(data.barHeight), theme.barHeightMin, theme.barHeightMax)
        }
        if (typeof data.barMargin === "number") {
            theme.barMargin = theme.clamp(Math.round(data.barMargin), theme.barMarginMin, theme.barMarginMax)
        }
        if (typeof data.barTopMargin === "number") {
            theme.barTopMargin = theme.clamp(Math.round(data.barTopMargin), 0, 24)
        }
        if (typeof data.radius === "number") theme.applyRadius(data.radius)
    }

    function persist() {
        theme.saveRequested()
    }

    function resetAppearance() {
        theme.barHeight = 38
        theme.barMargin = 10
        theme.barTopMargin = 8
        theme.applyRadius(10)
        theme.persist()
    }
}