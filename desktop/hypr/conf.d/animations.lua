hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeOutQuad", { type = "bezier", points = { { 0.5, 1 }, { 0.89, 1 } } })
hl.curve("easeInOutQuad", { type = "bezier", points = { { 0.45, 0 }, { 0.55, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "easeInOutQuad", style = "popin 90%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "easeOutQuad" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "easeOutQuad" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "easeOutQuad" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "easeOutQuad" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "easeOutQuad", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "easeOutQuad", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 3, bezier = "easeOutQuad" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3, bezier = "easeOutQuad" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
