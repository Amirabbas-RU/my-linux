const MODES = [
    { id: "apps", prefix: ">", label: "Applications", short: "Apps", hint: "Type an application name" },
    { id: "calc", prefix: "=", label: "Calculator", short: "Calc", hint: "Enter an expression, e.g. 2*(3+4)" },
    { id: "web", prefix: "?", label: "Web search", short: "Web", hint: "Search the web with DuckDuckGo" },
    { id: "wall", prefix: "wall:", label: "Wallpapers", short: "Wall", hint: "Pick a wallpaper" },
    { id: "clip", prefix: "clip:", label: "Clipboard", short: "Clip", hint: "Search clipboard history" },
    { id: "session", prefix: "session:", label: "Session", short: "Session", hint: "Lock, log out, suspend, reboot, shut down" }
]

function defaultProvider() {
    return { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%s" }
}

function all() {
    const out = []
    for (let i = 0; i < MODES.length; i++) {
        out.push({
            id: MODES[i].id,
            prefix: MODES[i].prefix,
            label: MODES[i].label,
            short: MODES[i].short,
            hint: MODES[i].hint
        })
    }
    return out
}

function providers() {
    return [
        { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%s" },
        { name: "Google", url: "https://www.google.com/search?q=%s" },
        { name: "Bing", url: "https://www.bing.com/search?q=%s" },
        { name: "Startpage", url: "https://www.startpage.com/sp/search?query=%s" },
        { name: "Searx", url: "https://searx.be/search?q=%s" },
        { name: "Brave", url: "https://search.brave.com/search?q=%s" },
        { name: "Ecosia", url: "https://www.ecosia.org/search?q=%s" },
        { name: "Wikipedia", url: "https://en.wikipedia.org/w/index.php?search=%s" }
    ]
}

function resolveProvider(name) {
    const wanted = String(name === undefined || name === null ? "" : name).trim().toLowerCase()
    const all = providers()
    for (let i = 0; i < all.length; i++) {
        if (all[i].name.toLowerCase() === wanted) return all[i]
    }
    return defaultProvider()
}

function buildUrl(query, providerName) {
    const provider = resolveProvider(providerName)
    return provider.url.replace("%s", encodeURIComponent(String(query)))
}

function parse(input) {
    const raw = String(input === undefined || input === null ? "" : input)
    if (raw.length > 0) {
        for (let i = 0; i < MODES.length; i++) {
            const mode = MODES[i]
            if (raw.length >= mode.prefix.length && raw.slice(0, mode.prefix.length).toLowerCase() === mode.prefix) {
                return {
                    mode: mode.id,
                    query: raw.slice(mode.prefix.length).replace(/^\s+/, ""),
                    explicit: true
                }
            }
        }
    }
    return { mode: "apps", query: raw, explicit: false }
}

function modeLabel(id) {
    for (let i = 0; i < MODES.length; i++) {
        if (MODES[i].id === id) return MODES[i].label
    }
    return "Applications"
}

function modeHint(id) {
    for (let i = 0; i < MODES.length; i++) {
        if (MODES[i].id === id) return MODES[i].hint
    }
    return MODES[0].hint
}

function prefixFor(id) {
    for (let i = 0; i < MODES.length; i++) {
        if (MODES[i].id === id) return MODES[i].prefix
    }
    return ""
}

function placeholder(id) {
    return modeHint(id)
}