function tokenize(input) {
    const s = String(input)
        .replace(/[\u00d7\u2715\u22c5]/g, "*")
        .replace(/[\u00f7]/g, "/")
        .replace(/[\u2212\u2013\u2014]/g, "-")
        .replace(/\u03c0/g, "pi")

    const tokens = []
    let i = 0
    const isDigit = (c) => c >= "0" && c <= "9"
    const isIdStart = (c) => /[A-Za-z_]/.test(c)
    const isIdPart = (c) => /[A-Za-z0-9_]/.test(c)

    while (i < s.length) {
        const c = s[i]
        if (c === " " || c === "\t" || c === "\n") { i++; continue }

        if (isDigit(c) || (c === "." && isDigit(s[i + 1]))) {
            let j = i
            while (j < s.length && (isDigit(s[j]) || s[j] === ".")) j++
            if (j < s.length && (s[j] === "e" || s[j] === "E")) {
                let k = j + 1
                if (k < s.length && (s[k] === "+" || s[k] === "-")) k++
                if (k < s.length && isDigit(s[k])) {
                    while (k < s.length && isDigit(s[k])) k++
                    j = k
                }
            }
            const text = s.slice(i, j)
            if ((text.match(/\./g) || []).length > 1) throw new Error("Malformed number: " + text)
            const value = Number(text)
            if (!isFinite(value)) throw new Error("Malformed number: " + text)
            tokens.push({ kind: "num", value: value })
            i = j
            continue
        }

        if (isIdStart(c)) {
            let j = i
            while (j < s.length && isIdPart(s[j])) j++
            tokens.push({ kind: "id", name: s.slice(i, j).toLowerCase() })
            i = j
            continue
        }

        if (c === "*" && s[i + 1] === "*") { tokens.push({ kind: "op", op: "^" }); i += 2; continue }
        if ("+-*/%^(),!".indexOf(c) !== -1) { tokens.push({ kind: "op", op: c }); i++; continue }

        throw new Error("Unsupported character: " + c)
    }

    if (tokens.length === 0) throw new Error("Empty expression")
    return tokens
}

const CONSTANTS = {
    pi: Math.PI,
    e: Math.E,
    tau: Math.PI * 2,
    phi: (1 + Math.sqrt(5)) / 2
}

const FUNCTIONS = {
    sqrt: (x) => Math.sqrt(x),
    cbrt: (x) => Math.cbrt(x),
    abs: (x) => Math.abs(x),
    sign: (x) => Math.sign(x),
    sin: (x) => Math.sin(x),
    cos: (x) => Math.cos(x),
    tan: (x) => Math.tan(x),
    asin: (x) => Math.asin(x),
    acos: (x) => Math.acos(x),
    atan: (x) => Math.atan(x),
    atan2: (y, x) => Math.atan2(y, x),
    sinh: (x) => Math.sinh(x),
    cosh: (x) => Math.cosh(x),
    tanh: (x) => Math.tanh(x),
    log: (x) => Math.log10(x),
    ln: (x) => Math.log(x),
    log2: (x) => Math.log2(x),
    exp: (x) => Math.exp(x),
    floor: (x) => Math.floor(x),
    ceil: (x) => Math.ceil(x),
    round: (x) => Math.round(x),
    trunc: (x) => Math.trunc(x),
    min: (a, b) => Math.min(a, b),
    max: (a, b) => Math.max(a, b),
    pow: (a, b) => Math.pow(a, b),
    hypot: (a, b) => Math.hypot(a, b)
}

const ARITY = {
    sqrt: 1, cbrt: 1, abs: 1, sign: 1, sin: 1, cos: 1, tan: 1,
    asin: 1, acos: 1, atan: 1, sinh: 1, cosh: 1, tanh: 1,
    log: 1, ln: 1, log2: 1, exp: 1, floor: 1, ceil: 1, round: 1, trunc: 1,
    atan2: 2, min: 2, max: 2, pow: 2, hypot: 2
}

function factorial(n) {
    if (!Number.isInteger(n)) throw new Error("fact needs a whole number")
    if (n < 0) throw new Error("fact needs n >= 0")
    if (n > 170) throw new Error("fact argument too large")
    let r = 1
    for (let i = 2; i <= n; i++) r *= i
    return r
}

function parse(tokens) {
    let pos = 0

    const peek = () => tokens[pos]
    const isOp = (op) => { const t = tokens[pos]; return t && t.kind === "op" && t.op === op }
    const expect = (op) => {
        if (!isOp(op)) throw new Error("Expected '" + op + "'")
        pos++
    }

    function parseExpression() {
        let left = parseTerm()
        while (isOp("+") || isOp("-")) {
            const op = tokens[pos].op
            pos++
            const right = parseTerm()
            left = op === "+" ? left + right : left - right
        }
        return left
    }

    function startsPrimary() {
        const t = peek()
        if (!t) return false
        if (t.kind === "num") return true
        if (t.kind === "id") return true
        return t.kind === "op" && t.op === "("
    }

    function parseTerm() {
        let left = parseUnary()
        for (;;) {
            if (isOp("*") || isOp("/") || isOp("%")) {
                const op = tokens[pos].op
                pos++
                const right = parseUnary()
                if (op === "*") left = left * right
                else if (op === "/") {
                    if (right === 0) throw new Error("Division by zero")
                    left = left / right
                } else {
                    if (right === 0) throw new Error("Division by zero")
                    left = left % right
                }
            } else if (startsPrimary()) {
                left = left * parseUnary()
            } else {
                return left
            }
        }
    }

    function parseUnary() {
        if (isOp("-")) { pos++; return -parseUnary() }
        if (isOp("+")) { pos++; return parseUnary() }
        return parsePower()
    }

    function parsePower() {
        let base = parsePrimary()
        while (isOp("!")) {
            pos++
            base = factorial(base)
        }
        if (isOp("^")) {
            pos++
            const exponent = parseUnary()
            return Math.pow(base, exponent)
        }
        return base
    }

    function parsePrimary() {
        const t = peek()
        if (!t) throw new Error("Unexpected end of expression")

        if (t.kind === "num") { pos++; return t.value }

        if (t.kind === "id") {
            pos++
            const name = t.name
            if (isOp("(")) {
                pos++
                const args = []
                if (!isOp(")")) {
                    args.push(parseExpression())
                    while (isOp(",")) {
                        pos++
                        args.push(parseExpression())
                    }
                }
                expect(")")
                if (name === "fact") {
                    if (args.length !== 1) throw new Error("fact takes one argument")
                    return factorial(args[0])
                }
                const fn = FUNCTIONS[name]
                if (!fn) throw new Error("Unknown function: " + name)
                const wanted = ARITY[name]
                if (args.length !== wanted) {
                    throw new Error(name + " takes " + wanted + " argument" + (wanted === 1 ? "" : "s"))
                }
                return fn.apply(null, args)
            }
            if (Object.prototype.hasOwnProperty.call(CONSTANTS, name)) return CONSTANTS[name]
            throw new Error("Unknown name: " + name)
        }

        if (t.kind === "op" && t.op === "(") {
            pos++
            const value = parseExpression()
            expect(")")
            return value
        }

        throw new Error("Unexpected token: " + (t.op || t.name || t.kind))
    }

    const result = parseExpression()
    if (pos !== tokens.length) throw new Error("Unexpected trailing input")
    return result
}

function evaluate(input) {
    const text = String(input).trim()
    if (text.length === 0) throw new Error("Empty expression")
    if (text.length > 200) throw new Error("Expression too long")
    const result = parse(tokenize(text))
    if (typeof result !== "number" || !isFinite(result)) throw new Error("Not a finite number")
    return result
}

function format(value) {
    if (!isFinite(value)) throw new Error("Not a finite number")
    if (value === 0) return "0"
    const abs = Math.abs(value)
    if (abs >= 1e12 || abs < 1e-9) return value.toExponential(8).replace(/\.?0+e/, "e").replace("e+", "e")
    let text = value.toPrecision(12)
    if (text.indexOf(".") !== -1) text = text.replace(/0+$/, "").replace(/\.$/, "")
    return text
}

function looksLikeExpression(input) {
    const text = String(input).trim()
    if (text.length === 0) return false
    if (!/[0-9]/.test(text)) return false
    try {
        evaluate(text)
        return true
    } catch (e) {
        return false
    }
}

function compute(input) {
    try {
        const value = evaluate(input)
        return { ok: true, value: value, text: format(value), error: "" }
    } catch (e) {
        return { ok: false, value: 0, text: "", error: String(e && e.message ? e.message : e) }
    }
}