class_name MathFormatter
extends RefCounted
## Turns the math engine's plain-text output into readable display strings,
## parses numeric lists for plotting, and validates user input.

const _SUP := {
	"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
	"5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
	"-": "⁻", "+": "⁺",
}

# Task 264 (MR-S1) — two-char relational/arrow operators → Unicode. Ordered;
# applied before the single-char passes.
const _OPS := [
	["<=", "≤"], [">=", "≥"], ["/=", "≠"], ["!=", "≠"], ["<>", "≠"],
	["=>", "⇒"], ["->", "→"],
]

# Task 264 (MR-S1) — whole-word function/constant names → math symbols. Applied
# on identifier boundaries so `sqrt`→`√` but a variable like `sqrt_x` is untouched,
# and `sin`/`cos`/`log` (absent here) pass through unchanged.
const _WORDS := {
	"infinity": "∞", "infty": "∞", "sqrt": "√", "int": "∫", "partial": "∂",
	"nabla": "∇", "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ",
	"epsilon": "ε", "theta": "θ", "kappa": "κ", "lambda": "λ", "mu": "μ",
	"nu": "ν", "pi": "π", "rho": "ρ", "sigma": "σ", "tau": "τ", "phi": "φ",
	"chi": "χ", "psi": "ψ", "omega": "ω",
}

## Convert the engine's linear form (e.g. "x**2 + 2*x + 1$") into readable
## display text: "x² + 2·x + 1". Task 264 widens this: relational/arrow operators
## and function/constant names map to Unicode, and exponents handle signs and
## parentheses (`x^(-2)`→`x⁻²`). Non-mappable exponents keep the "^" caret.
static func to_display(s: String) -> String:
	var out := s.strip_edges().trim_suffix("$")   # linear-mode lines end with '$'
	out = out.replace("**", "^")                  # engine power operator -> ^
	for op in _OPS:
		out = out.replace(op[0], op[1])
	# Exponents -> Unicode superscripts: ^12, ^(-2), ^(3) all handled.
	out = _superscript(out)
	# Whole-word symbol names (identifier boundaries only).
	out = _wordsub(out)
	out = out.replace("*", "·")   # explicit multiplication dot reads cleaner
	return out


## Replace `^<digits>` / `^(<±digits>)` with Unicode superscripts, dropping the
## caret and parens. A non-numeric exponent (e.g. `^n`) is left as `^n`.
##
## Two ordered passes so the closing paren of an OUTER group is never eaten:
## a single greedy `\^\(?…\)?` turned `sqrt(x^2)` into `√(x²` (task 272 bug). Pass 1
## matches only a fully-parenthesised `^(…)`; pass 2 matches a bare `^…` with no
## parens, so a `)` that belongs to an enclosing call is left intact.
static func _superscript(s: String) -> String:
	var out := _sup_pass(s, "\\^\\(([+-]?[0-9]+)\\)")   # ^(<±digits>)
	out = _sup_pass(out, "\\^([+-]?[0-9]+)")            # ^<±digits>
	return out


static func _sup_pass(s: String, pattern: String) -> String:
	var out := s
	var re := RegEx.new()
	re.compile(pattern)
	while true:
		var m := re.search(out)
		if m == null:
			break
		var sup := ""
		for ch in m.get_string(1):
			sup += _SUP.get(ch, ch)
		out = out.substr(0, m.get_start()) + sup + out.substr(m.get_end())
	return out


## Replace whole-identifier tokens found in `_WORDS` with their math symbol,
## leaving every other identifier (variables, `sin`, `cos`, …) untouched.
static func _wordsub(s: String) -> String:
	var re := RegEx.new()
	re.compile("[A-Za-z_][A-Za-z0-9_]*")
	var out := ""
	var last := 0
	for m in re.search_all(s):
		out += s.substr(last, m.get_start() - last)
		out += _WORDS.get(m.get_string(), m.get_string())
		last = m.get_end()
	out += s.substr(last)
	return out


## Task 265/266 (MR-S3/S4) — turn a `to_display`-formatted string into **BBCode**
## for the result RichTextLabel: literal `[` escaped, REDUCE matrices
## `mat((..),(..))` laid out as a `[table]` grid, and multi-character / symbolic
## exponents (`x^(n+1)`, `x^n`) raised via `[sup]` (a task-266 custom RichTextEffect
## supplies the tag Godot lacks). Numeric exponents are already Unicode superscripts.
## The saved `.md` keeps the clean Unicode form; only the on-screen cell uses BBCode.
static func to_bbcode(s: String) -> String:
	var out := s.replace("[", "[lb]")          # escape literal brackets first
	out = _matrices_to_bbcode(out)
	out = _superscript_bbcode(out)
	return out


static func _is_exp_char(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
		or (c >= "0" and c <= "9") or c == "_" or c == "."


## Raise the operand after each remaining `^`: a balanced `(…)` group, else a run
## of identifier/number chars. `x^(n+1)`→`x[sup]n+1[/sup]`, `x^n`→`x[sup]n[/sup]`.
static func _superscript_bbcode(s: String) -> String:
	var out := ""
	var i := 0
	while i < s.length():
		if s[i] != "^":
			out += s[i]
			i += 1
			continue
		var j := i + 1
		var exp := ""
		if j < s.length() and s[j] == "(":
			var depth := 0
			var start := j
			while j < s.length():
				if s[j] == "(":
					depth += 1
				elif s[j] == ")":
					depth -= 1
				j += 1
				if depth == 0:
					break
			exp = s.substr(start + 1, j - start - 2)
		else:
			var start := j
			while j < s.length() and _is_exp_char(s[j]):
				j += 1
			exp = s.substr(start, j - start)
		if exp == "":
			out += "^"
			i += 1
		else:
			out += "[sup]" + exp + "[/sup]"
			i = j
	return out


## Replace every `mat((row),(row),…)` with a `[table]` grid.
static func _matrices_to_bbcode(s: String) -> String:
	var out := s
	var guard := 0
	while guard < 40:
		guard += 1
		var idx := out.find("mat(")
		if idx == -1:
			break
		var p := idx + 3                        # the '(' after "mat"
		var depth := 0
		var end := p
		while end < out.length():
			if out[end] == "(":
				depth += 1
			elif out[end] == ")":
				depth -= 1
			end += 1
			if depth == 0:
				break
		var inner := out.substr(p + 1, end - p - 2)
		var table := _rows_to_table(inner)
		if table == "":
			break                               # parse failed — avoid infinite loop
		out = out.substr(0, idx) + table + out.substr(end)
	return out


static func _rows_to_table(inner: String) -> String:
	var rows := _split_top_commas(inner)        # ["(1,2)", "(3,4)"]
	if rows.is_empty():
		return ""
	var cols := 0
	var grid: Array = []
	for rs in rows:
		var r: String = rs.strip_edges()
		if r.begins_with("(") and r.ends_with(")"):
			r = r.substr(1, r.length() - 2)
		var cells := _split_top_commas(r)
		cols = maxi(cols, cells.size())
		grid.append(cells)
	if cols == 0:
		return ""
	var bb := "[table=%d]" % cols
	for cells in grid:
		for c in cells:
			bb += "[cell]" + String(c).strip_edges() + "[/cell]"
	return bb + "[/table]"


## Split a string by commas at parenthesis-depth 0 (nested calls stay intact).
static func _split_top_commas(s: String) -> Array:
	var parts: Array = []
	var depth := 0
	var cur := ""
	for ch in s:
		if ch == "(" or ch == "[":
			depth += 1
			cur += ch
		elif ch == ")" or ch == "]":
			depth -= 1
			cur += ch
		elif ch == "," and depth == 0:
			parts.append(cur)
			cur = ""
		else:
			cur += ch
	parts.append(cur)
	return parts


## True if the engine reported an error (error lines start with *****).
static func is_error(s: String) -> bool:
	return s.contains("*****")


## Make an engine error readable instead of dumping raw asterisks.
static func clean_error(s: String) -> String:
	var msg := s.replace("*****", "").strip_edges()
	return "⚠ " + msg


## Parse a list like "{1,2,5,10,17,26}" into a float array.
static func parse_number_list(s: String) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	var start := s.find("{")
	var stop := s.rfind("}")
	if start == -1 or stop == -1 or stop <= start:
		return result
	var inner := s.substr(start + 1, stop - start - 1)
	for part in inner.split(",", false):
		var t := part.strip_edges()
		if t.is_valid_float():
			result.append(t.to_float())
	return result


## Light client-side validation before sending (task-4 §3): balanced brackets.
## Returns "" when ok, otherwise a human message.
static func validate(expr: String) -> String:
	var depth := 0
	for ch in expr:
		if ch == "(":
			depth += 1
		elif ch == ")":
			depth -= 1
			if depth < 0:
				return "Unbalanced parentheses: extra ')'"
	if depth > 0:
		return "Unbalanced parentheses: missing ')'"
	if expr.strip_edges().is_empty():
		return "Expression is empty"
	return ""


## Free single-letter symbols other than 'x' and 'e' — candidates for sliders
## (task-4 §4 parameter sliders).
static func free_params(expr: String) -> PackedStringArray:
	var found := {}
	var re := RegEx.new()
	re.compile("[A-Za-z_][A-Za-z0-9_]*")
	var reserved := ["x", "e", "i", "pi", "sin", "cos", "tan", "log", "exp",
		"sqrt", "df", "int", "abs", "atan", "asin", "acos"]
	for m in re.search_all(expr):
		var name := m.get_string()
		if name.length() == 1 and name == name.to_lower() \
				and not reserved.has(name) and name != "x":
			found[name] = true
	var out := PackedStringArray()
	for k in found.keys():
		out.append(k)
	out.sort()
	return out
