import QtQuick

Item {
    id: root

    property real strength: 0.05
    property int tile: 160
    property real radius: 0

    Image {
        id: grainSource
        source: "../../assets/grain.png"
        visible: false
        asynchronous: false
    }

    Canvas {
        anchors.fill: parent
        opacity: root.strength

        property int cornerRadius: root.radius
        property int tileSize: root.tile

        onCornerRadiusChanged: requestPaint()
        onTileSizeChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.save()

            const w = width
            const h = height
            const r = Math.max(0, Math.min(cornerRadius, Math.min(w, h) / 2))

            ctx.beginPath()
            ctx.moveTo(r, 0)
            ctx.lineTo(w - r, 0)
            ctx.arcTo(w, 0, w, r, r)
            ctx.lineTo(w, h - r)
            ctx.arcTo(w, h, w - r, h, r)
            ctx.lineTo(r, h)
            ctx.arcTo(0, h, 0, h - r, r)
            ctx.lineTo(0, r)
            ctx.arcTo(0, 0, r, 0, r)
            ctx.closePath()
            ctx.clip()

            const step = Math.max(1, tileSize)
            for (let y = 0; y < h; y += step) {
                for (let x = 0; x < w; x += step) {
                    ctx.drawImage(grainSource, x, y, step, step)
                }
            }

            ctx.restore()
        }
    }
}