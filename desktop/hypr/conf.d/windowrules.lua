hl.window_rule({ match = { class = "^(xdg-desktop-portal-.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Open File)$" }, float = true })
hl.window_rule({ match = { title = "^(Save File)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)$" }, float = true })

hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(hyprpolkitagent)$" }, float = true })

hl.window_rule({
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    size = { 480, 270 },
    move = { "monitor_w - 490", "monitor_h - 280" },
})

hl.window_rule({ match = { class = "^(nwg-look)$" }, float = true })
hl.window_rule({ match = { class = "^(qt6ct)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, size = { 900, 600 } })

hl.window_rule({ match = { class = "^(mpv)$" }, tile = true })
hl.window_rule({ match = { class = "^(.*)$" }, idle_inhibit = "fullscreen" })

hl.window_rule({ match = { class = "^(.*)$" }, suppress_event = "maximize" })
hl.window_rule({
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$", workspace = "1" },
    no_focus = true,
})
