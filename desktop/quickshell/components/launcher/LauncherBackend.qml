import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"
import "../../logic/Calc.js" as Calc
import "../../logic/Match.js" as Match

Item {
    id: backend

    visible: false
    width: 0
    height: 0

    property var appEntries: []
    property bool appsReady: false

    property var favorites: []
    property string provider: "DuckDuckGo"
    property string currentWallpaper: ""

    property var wallpapers: []
    property bool wallpaperBackendMissing: false

    property var clipboardEntries: []
    property bool clipboardAvailable: true

    property string lastError: ""

    property var pendingLaunch: null

    property bool stateReady: false
    property bool stateLoaded: false

    readonly property string wallpaperDir: "/usr/share/mylinux/wallpapers"
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/mylinux/launcher.json"

    function sanitizeFavoriteIds(list) {
        const out = []
        if (!list) return out
        for (let i = 0; i < list.length; i++) {
            const id = String(list[i])
            if (id.length > 0 && out.indexOf(id) === -1) out.push(id)
        }
        return out
    }

    FileView {
        id: stateView
        path: backend.stateFile
        watchChanges: false
        atomicWrites: true
        onLoaded: backend.loadState(text())
        onLoadFailed: backend.loadState("")
        onSaveFailed: backend.lastError = "Could not save launcher settings"
    }

    function loadState(raw) {
        if (backend.stateLoaded) return
        backend.stateLoaded = true
        let data = null
        try {
            data = JSON.parse(raw)
        } catch (e) {
            data = null
        }
        if (data && typeof data === "object") {
            backend.favorites = backend.sanitizeFavoriteIds(data.favorites)
            if (typeof data.provider === "string" && data.provider.length > 0) backend.provider = data.provider
            if (typeof data.wallpaper === "string") backend.persistedWallpaper = data.wallpaper
        }
        backend.stateReady = true
        backend.reloadApplications()
        backend.reloadWallpapers()
        backend.restoreWallpaperAtStartup()
    }

    property var persistedWallpaper: ""
    property bool applyInFlight: false

    function restoreWallpaperAtStartup() {
        const target = backend.persistedWallpaper.length > 0
            ? backend.persistedWallpaper
            : backend.wallpaperDir + "/mylinux-default.png"
        if (target.length === 0) return
        backend.currentWallpaper = target
        backend.applyInFlight = true
        startupRestoreProc.command = ["sh", "-c",
            "pgrep -x awww-daemon >/dev/null 2>&1 || (setsid awww-daemon >/dev/null 2>&1 &); sleep 0.4; awww img \"$1\"",
            "sh", target]
        startupRestoreProc.running = false
        startupRestoreProc.running = true
    }

    Process {
        id: startupRestoreProc
        onExited: function (code) {
            backend.applyInFlight = false
            if (code !== 0) backend.wallpaperBackendMissing = true
        }
    }

    function persist() {
        if (!backend.stateReady) return
        stateView.setText(JSON.stringify({
            favorites: backend.favorites,
            provider: backend.provider,
            wallpaper: backend.currentWallpaper
        }))
    }

    function isFavorite(id) {
        return backend.favorites.indexOf(id) !== -1
    }

    function toggleFavorite(id) {
        const list = backend.favorites.slice()
        const at = list.indexOf(id)
        if (at === -1) list.push(id)
        else list.splice(at, 1)
        backend.favorites = list
        backend.persist()
    }

    function setProvider(name) {
        if (!name) return
        backend.provider = String(name)
        backend.persist()
    }

    function reloadApplications() {
        const model = DesktopEntries.applications
        const items = model ? (model.values ? model.values : []) : []
        const out = []
        for (let i = 0; i < items.length; i++) {
            const app = items[i]
            if (!app || app.noDisplay) continue
            const keywords = app.keywords ? String(app.keywords).split(";").join(" ") : ""
            out.push({
                id: app.id,
                name: app.name || app.id,
                genericName: app.genericName || "",
                comment: app.comment || "",
                keywords: keywords,
                icon: app.icon || "",
                exec: app.execString || "",
                app: app
            })
        }
        out.sort(function (a, b) { return a.name.localeCompare(b.name) })
        backend.appEntries = out
        backend.appsReady = true
    }

    function rankApps(query) {
        return Match.rank(backend.appEntries, query, backend.favorites)
    }

    function launchApp(descriptor) {
        if (!descriptor) return
        const entry = descriptor.entry
        const app = entry && entry.app ? entry.app : null
        const argv = app && app.command && app.command.length > 0
            ? app.command.slice() : []
        if (argv.length === 0) {
            backend.lastError = "Cannot launch " + (descriptor.name || "application")
            return
        }
        backend.pendingLaunch = { app: app, argv: argv, name: descriptor.name || argv[0] }
        launchCheckProc.command = ["which", argv[0]]
        launchCheckProc.running = false
        launchCheckProc.running = true
    }

    Process {
        id: launchCheckProc
        onExited: function (code) {
            const pending = backend.pendingLaunch
            backend.pendingLaunch = null
            if (!pending) return
            if (code !== 0) {
                backend.lastError = "Cannot launch " + pending.name + ": executable not found"
                return
            }
            if (pending.app && typeof pending.app.execute === "function") {
                try {
                    pending.app.execute()
                    backend.lastError = ""
                    return
                } catch (e) {
                    backend.lastError = "Launch failed: " + e
                    return
                }
            }
            Quickshell.execDetached(pending.argv)
        }
    }

    function reloadWallpapers() {
        wallpaperListProc.running = false
        wallpaperListProc.running = true
    }

    Process {
        id: wallpaperListProc
        command: ["sh", "-c",
            "find \"$1\" -maxdepth 1 -type f \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \\) 2>/dev/null | sort",
            "sh", backend.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(function (l) { return l.trim().length > 0 })
                const out = []
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].trim()
                    const base = p.substring(p.lastIndexOf("/") + 1)
                    let name = base.replace(/\.[^.]+$/, "")
                    name = name.replace(/^mylinux-/, "").replace(/-/g, " ")
                    name = name.replace(/\b\w/g, function (c) { return c.toUpperCase() })
                    out.push({ path: p, name: name, file: "file://" + p })
                }
                backend.wallpapers = out
            }
        }
    }

    function reloadCurrentWallpaper() {
        wallpaperQueryProc.running = false
        wallpaperQueryProc.running = true
    }

    Process {
        id: wallpaperQueryProc
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (backend.applyInFlight) return
                const out = text
                const marker = "currently displaying: image: "
                const at = out.indexOf(marker)
                if (at !== -1) backend.currentWallpaper = out.substring(at + marker.length).trim()
            }
        }
        onExited: function (code) {
            backend.wallpaperBackendMissing = (code !== 0)
        }
    }

    function applyWallpaper(path) {
        if (!path) return
        backend.currentWallpaper = String(path)
        backend.persist()
        wallpaperApplyProc.command = ["sh", "-c",
            "pgrep -x awww-daemon >/dev/null 2>&1 || (setsid awww-daemon >/dev/null 2>&1 &); sleep 0.3; awww img \"$1\"",
            "sh", String(path)]
        wallpaperApplyProc.running = false
        wallpaperApplyProc.running = true
    }

    Process {
        id: wallpaperApplyProc
        onExited: function (code) {
            if (code !== 0) {
                backend.lastError = "Could not apply wallpaper"
                backend.wallpaperBackendMissing = true
            } else {
                backend.wallpaperBackendMissing = false
                backend.lastError = ""
            }
        }
    }

    function reloadClipboard() {
        clipboardListProc.running = false
        clipboardListProc.running = true
    }

    Process {
        id: clipboardListProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const out = []
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    if (line.length === 0) continue
                    const tab = line.indexOf("\t")
                    if (tab === -1) continue
                    const id = line.substring(0, tab).trim()
                    let preview = line.substring(tab + 1)
                    if (preview.indexOf("[[ binary data") !== -1) preview = "Image or binary data"
                    out.push({ id: id, preview: preview.replace(/\s+/g, " ").trim() })
                }
                backend.clipboardEntries = out
                backend.clipboardAvailable = true
            }
        }
        onExited: function (code) {
            if (code !== 0) backend.clipboardAvailable = false
        }
    }

    function copyClipboardEntry(id) {
        clipboardCopyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", String(id)]
        clipboardCopyProc.running = false
        clipboardCopyProc.running = true
    }

    Process {
        id: clipboardCopyProc
        onExited: function (code) {
            if (code !== 0) backend.lastError = "Could not copy clipboard entry"
        }
    }

    function clearClipboard() {
        clipboardWipeProc.running = false
        clipboardWipeProc.running = true
    }

    Process {
        id: clipboardWipeProc
        command: ["cliphist", "wipe"]
        onExited: function (code) {
            if (code === 0) {
                backend.clipboardEntries = []
                backend.lastError = ""
            } else {
                backend.lastError = "Could not clear clipboard history"
            }
        }
    }

    function copyText(text) {
        if (text === undefined || text === null) return
        Quickshell.clipboardText = String(text)
    }

    function openUrl(url) {
        if (!url) return
        Quickshell.execDetached(["xdg-open", String(url)])
    }

    function compute(text) {
        return Calc.compute(text)
    }

    function runSessionAction(action) {
        if (action === "lock") Quickshell.execDetached(["hyprlock"])
        else if (action === "logout") Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
        else if (action === "suspend") Quickshell.execDetached(["systemctl", "suspend"])
        else if (action === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
        else if (action === "shutdown") Quickshell.execDetached(["systemctl", "poweroff"])
    }
}