local keyboard = { layout = "us", variant = "", options = "" }

local ok, installed = pcall(require, "keyboard")
if ok and type(installed) == "table" then
    keyboard = installed
end

hl.config({
    input = {
        kb_layout = keyboard.layout or "us",
        kb_variant = keyboard.variant or "",
        kb_model = "",
        kb_options = keyboard.options or "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = 0,

        numlock_by_default = false,
        repeat_delay = 300,
        repeat_rate = 40,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            scroll_factor = 1.0,
            tap_to_click = true,
            clickfinger_behavior = false,
        },
    },
    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})
