function normalize(text) {
    return String(text === undefined || text === null ? "" : text).toLowerCase()
}

function isBoundary(text, index) {
    if (index === 0) return true
    const prev = text.charAt(index - 1)
    return prev === " " || prev === "-" || prev === "_" || prev === "." || prev === "/"
}

function subsequence(haystack, needle) {
    const positions = []
    let h = 0
    let n = 0
    let gaps = 0
    let runs = 0
    let last = -2
    while (h < haystack.length && n < needle.length) {
        if (haystack.charAt(h) === needle.charAt(n)) {
            positions.push(h)
            if (h === last + 1) runs++
            else if (n > 0) gaps++
            last = h
            n++
        }
        h++
    }
    if (n < needle.length) return null
    return { positions: positions, gaps: gaps, runs: runs }
}

function score(text, needle, allowSubsequence) {
    const source = normalize(text)
    const query = normalize(needle)
    if (query.length === 0) return { match: true, score: 0, positions: [] }
    if (source.length === 0) return { match: false, score: 0, positions: [] }

    if (source === query) {
        const p = []
        for (let i = 0; i < query.length; i++) p.push(i)
        return { match: true, score: 1200, positions: p }
    }

    if (source.startsWith(query)) {
        const p = []
        for (let i = 0; i < query.length; i++) p.push(i)
        return { match: true, score: 1000 - Math.min(80, source.length - query.length), positions: p }
    }

    const at = source.indexOf(query)
    if (at !== -1 && isBoundary(source, at)) {
        const p = []
        for (let i = 0; i < query.length; i++) p.push(at + i)
        return { match: true, score: 880 - Math.min(60, at), positions: p }
    }

    if (at !== -1) {
        const p = []
        for (let i = 0; i < query.length; i++) p.push(at + i)
        return { match: true, score: 700 - Math.min(120, at * 4), positions: p }
    }

    if (!allowSubsequence) return { match: false, score: 0, positions: [] }

    if (query.length > 1) {
        const words = source.split(/[\s\-_./]+/).filter((w) => w.length > 0)
        let initials = ""
        for (let i = 0; i < words.length; i++) initials += words[i].charAt(0)
        if (initials.startsWith(query)) {
            return { match: true, score: 620, positions: [] }
        }
    }

    const sub = subsequence(source, query)
    if (sub) {
        const penalty = sub.gaps * 12
        const bonus = sub.runs * 6
        const density = query.length / source.length
        const raw = 520 - penalty + bonus + Math.round(density * 60)
        if (raw < 380) return { match: false, score: 0, positions: [] }
        return { match: true, score: Math.max(60, raw), positions: sub.positions }
    }

    return { match: false, score: 0, positions: [] }
}

const FIELDS = [
    { key: "name", weight: 1.0, fuzzy: true },
    { key: "genericName", weight: 0.72, fuzzy: false },
    { key: "keywords", weight: 0.6, fuzzy: false },
    { key: "comment", weight: 0.5, fuzzy: false },
    { key: "id", weight: 0.28, fuzzy: false }
]

function matchEntry(entry, needle) {
    const query = String(needle === undefined || needle === null ? "" : needle).trim()
    if (query.length === 0) {
        return { match: true, score: 0, positions: [], field: "" }
    }

    let best = { match: false, score: 0, positions: [], field: "" }
    for (let i = 0; i < FIELDS.length; i++) {
        const field = FIELDS[i]
        const raw = entry[field.key]
        if (raw === undefined || raw === null || raw === "") continue
        const result = score(raw, query, field.fuzzy)
        if (!result.match) continue
        const weighted = Math.round(result.score * field.weight)
        if (weighted > best.score) {
            best = {
                match: true,
                score: weighted,
                positions: field.key === "name" ? result.positions : [],
                field: field.key
            }
        }
    }
    return best
}

function rank(entries, needle, favorites) {
    const favouriteOrder = {}
    if (favorites) {
        for (let i = 0; i < favorites.length; i++) favouriteOrder[favorites[i]] = i
    }
    const out = []
    const query = String(needle === undefined || needle === null ? "" : needle).trim()

    for (let i = 0; i < entries.length; i++) {
        const entry = entries[i]
        const result = matchEntry(entry, query)
        if (!result.match) continue
        const pinned = Object.prototype.hasOwnProperty.call(favouriteOrder, entry.id)
        out.push({
            id: entry.id,
            name: entry.name,
            comment: entry.comment || "",
            genericName: entry.genericName || "",
            icon: entry.icon || "",
            exec: entry.exec,
            entry: entry,
            pinned: pinned,
            favouriteIndex: pinned ? favouriteOrder[entry.id] : -1,
            score: result.score,
            positions: result.positions,
            field: result.field
        })
    }

    out.sort(function (a, b) {
        if (query.length === 0) {
            if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
            if (a.pinned && b.pinned) return a.favouriteIndex - b.favouriteIndex
            return a.name.localeCompare(b.name)
        }
        if (a.pinned !== b.pinned) {
            const bonus = a.pinned ? 40 : 0
            if (b.score - a.score > bonus) return b.score - a.score
            if (a.score - b.score > bonus) return a.score - b.score
            return a.pinned ? -1 : 1
        }
        if (a.score !== b.score) return b.score - a.score
        return a.name.localeCompare(b.name)
    })

    return out
}