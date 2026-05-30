class_name MathFormatter
extends RefCounted
## Turns the math engine's plain-text output into readable display strings,
## parses numeric lists for plotting, and validates user input.

const _SUP := {
	"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
	"5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
}

## Convert the engine's linear form (e.g. "x**2 + 2*x + 1$") into readable
## display text: "x² + 2x + 1". The RichTextLabel has no [sup] tag, so real
## Unicode superscripts are used for numeric exponents, with "^" as the
## fallback for non-numeric exponents.
static func to_display(s: String) -> String:
	var out := s.strip_edges().trim_suffix("$")   # linear-mode lines end with '$'
	out = out.replace("**", "^")                  # engine power operator -> ^
	# Numeric exponents -> Unicode superscripts (drops the caret).
	var re := RegEx.new()
	re.compile("\\^(\\d+)")
	while true:
		var m := re.search(out)
		if m == null:
			break
		var sup := ""
		for ch in m.get_string(1):
			sup += _SUP.get(ch, ch)
		out = out.substr(0, m.get_start()) + sup + out.substr(m.get_end())
	out = out.replace("*", "·")   # explicit multiplication dot reads cleaner
	return out


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
