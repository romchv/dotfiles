pragma Singleton

import Quickshell

// Expression evaluation and number formatting for the calculator overlay.
// Expressions hold + - * / % ( ) and numbers in base 10, 16 or 2, × and ÷
// before + and −. `a + b%` adds b percent of a, as on a desk calculator;
// elsewhere b% is b/100. Bases 16 and 2 work on whole numbers (division
// truncates, no % or decimals). Missing ")" at the end are implied.
Singleton {
    // { ok: true, value } or { ok: false, error }.
    function evaluate(expr, base) {
        const tokens = tokenize(expr, base);
        if (!tokens)
            return { ok: false, error: "Invalid input" };
        if (!tokens.length)
            return { ok: false, error: "Incomplete" };

        let pos = 0;
        const fail = msg => {
            throw new Error(msg);
        };

        // Number or parenthesized expression.
        function primary() {
            const t = tokens[pos++];
            if (typeof t === "number")
                return t;
            if (t === "(") {
                const v = sum();
                if (tokens[pos] === ")")
                    pos++;
                else if (pos < tokens.length)
                    fail("Invalid input");
                return v;
            }
            fail(t === undefined ? "Incomplete" : "Invalid input");
        }

        // { value, percent }: percent is b for a bare `b%`, else null.
        function unary() {
            if (tokens[pos] === "-" || tokens[pos] === "+") {
                const negate = tokens[pos++] === "-";
                const u = unary();
                return negate ? { value: -u.value, percent: u.percent === null ? null : -u.percent } : u;
            }
            const v = primary();
            if (tokens[pos] === "%") {
                pos++;
                return { value: v / 100, percent: v };
            }
            return { value: v, percent: null };
        }

        function product() {
            const first = unary();
            let value = first.value;
            if (tokens[pos] !== "*" && tokens[pos] !== "/")
                return first;
            while (tokens[pos] === "*" || tokens[pos] === "/") {
                const op = tokens[pos++];
                const rhs = unary().value;
                if (op === "*")
                    value *= rhs;
                else if (rhs === 0)
                    fail("Can't divide by zero");
                else
                    value = base === 10 ? value / rhs : Math.trunc(value / rhs);
            }
            return { value, percent: null };
        }

        function sum() {
            let value = product().value;
            while (tokens[pos] === "+" || tokens[pos] === "-") {
                const op = tokens[pos++];
                const rhs = product();
                const delta = rhs.percent === null ? rhs.value : value * rhs.percent / 100;
                value = op === "+" ? value + delta : value - delta;
            }
            return value;
        }

        try {
            const value = sum();
            if (pos < tokens.length)
                fail("Invalid input");
            if (!isFinite(value))
                fail("Out of range");
            return { ok: true, value };
        } catch (e) {
            return { ok: false, error: e.message };
        }
    }

    // Numbers and operator characters, or null on a character the base can't use.
    function tokenize(expr, base) {
        const digit = base === 16 ? /[0-9A-F]/ : base === 2 ? /[01]/ : /[0-9.]/;
        const tokens = [];
        let i = 0;
        while (i < expr.length) {
            const c = expr[i];
            if (digit.test(c)) {
                let j = i;
                while (j < expr.length && digit.test(expr[j]))
                    j++;
                const run = expr.slice(i, j);
                if (base === 10 && (run === "." || run.split(".").length > 2))
                    return null;
                tokens.push(base === 10 ? parseFloat(run) : parseInt(run, base));
                i = j;
            } else if ("+-*/()".includes(c) || (c === "%" && base === 10)) {
                tokens.push(c);
                i++;
            } else if (c === " ") {
                i++;
            } else {
                return null;
            }
        }
        return tokens;
    }

    // Plain form, for copying and for continuing from a result:
    // 12 significant digits in base 10, whole numbers otherwise.
    function raw(value, base) {
        if (base === 10)
            return String(Number(value.toPrecision(12)));
        const n = Math.trunc(value);
        return (n < 0 ? "-" : "") + Math.abs(n).toString(base).toUpperCase();
    }

    // Display form: thousands separators in base 10, groups of four digits otherwise.
    function format(value, base) {
        const s = raw(value, base);
        if (s.includes("e"))
            return s;
        const negative = s.startsWith("-");
        const parts = (negative ? s.slice(1) : s).split(".");
        const whole = base === 10 ? group(parts[0], 3, ",") : group(parts[0], 4, " ");
        return (negative ? "-" : "") + whole + (parts.length > 1 ? "." + parts[1] : "");
    }

    function group(digits, size, separator) {
        let out = "";
        for (let i = digits.length; i > 0; i -= size)
            out = digits.slice(Math.max(0, i - size), i) + (out ? separator + out : "");
        return out;
    }

    // Typed operators as shown: * / - become × ÷ −.
    function pretty(expr) {
        return expr.replace(/\*/g, "×").replace(/\//g, "÷").replace(/-/g, "−");
    }
}
