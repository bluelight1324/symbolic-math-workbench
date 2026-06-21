extends Node
## Task 95 — thorough test of the MATH FUNCTIONS, driven through the new
## (MATLAB-look) UI. Added as a child of Main when --math-test is on the
## command line.
##
## Unlike _uitest.gd (task 25), which checks UI *structure* with weak
## "contains" assertions, this harness verifies the *mathematical correctness*
## of the engine's answers as they appear in the UI:
##   • Phase A — operation buttons (Simplify / Factor / d/dx / ∫ / Solve / ODE)
##     against exact, independently-verified expected results.
##   • Phase B — breadth pass over EVERY problem-library item, asserting each
##     evaluates to a non-error result through the same click path.
##
## Every expected value in Phase A was cross-checked against REDUCE directly
## before being hard-coded here, so a mismatch means the UI/engine pipeline is
## wrong, not the expectation.

const MARKER := "i:/mathdot/mathtest_marker.txt"
const REPORT := "i:/mathdot/task95_mathtest_report.md"

var _main: Node
var _log: PackedStringArray = []
var _pass := 0
var _fail := 0

var _input: LineEdit
var _history_box: VBoxContainer
var _result_view: RichTextLabel
var _pending: Dictionary

# Superscript → digit, to reverse MathFormatter.to_display for comparison.
const _UNSUP := {
	"⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4",
	"⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9",
}


func _ready() -> void:
	_main = get_parent()
	_input = _main.get("_input") as LineEdit
	_history_box = _main.get("_history_box") as VBoxContainer
	_result_view = _main.get("_result_view") as RichTextLabel
	_pending = _main.get("_pending")
	await get_tree().create_timer(1.5).timeout
	_mark("boot done; MathEngine ready=" + str(MathEngine.is_ready()))
	_assert("Engine ready at start", MathEngine.is_ready())

	await _phase_operations()
	await _phase_library_breadth()

	_finish()


# ----------------------------------------------------------------------------
# Phase A — operation buttons vs exact, REDUCE-verified answers.
# ----------------------------------------------------------------------------
func _phase_operations() -> void:
	_log.append("\n## Phase A — operation buttons (exact-result checks)")
	# {name, expr, op, expect, mode}  — mode "exact" | "contains"
	# expect is written in normalised form: '^' for powers, '*' for products,
	# no spaces. _normalize() reverses the UI's pretty-printing before compare.
	var cases := [
		# Simplify / expand
		["Simplify (x+1)^2",        "(x+1)^2",        "simplify", "x^2+2*x+1",                          "exact"],
		["Simplify (x+1)^3",        "(x+1)^3",        "simplify", "x^3+3*x^2+3*x+1",                    "exact"],
		["Simplify (x^2-1)/(x-1)",  "(x^2-1)/(x-1)",  "simplify", "x+1",                                "exact"],
		# Factor
		["Factor x^6-1",            "x^6 - 1",        "factor",   "{{x^2+x+1,1},{x^2-x+1,1},{x+1,1},{x-1,1}}", "exact"],
		# Differentiate
		["d/dx x^3",                "x^3",            "diff",     "3*x^2",                              "exact"],
		["d/dx sin(x)*x",           "sin(x)*x",       "diff",     "cos(x)*x+sin(x)",                    "exact"],
		["d/dx atan(x)",            "atan(x)",        "diff",     "1/(x^2+1)",                          "exact"],
		["d/dx tan(x)",             "tan(x)",         "diff",     "tan(x)^2+1",                         "exact"],
		# Integrate
		["∫ 1/(x^2+1) dx",          "1/(x^2+1)",      "int",      "atan(x)",                            "exact"],
		["∫ x^2 dx",                "x^2",            "int",      "x^3/3",                              "exact"],
		["∫ cos(x) dx",             "cos(x)",         "int",      "sin(x)",                             "exact"],
		["∫ 1/x dx",                "1/x",            "int",      "log(x)",                             "exact"],
		["∫ log(x) dx",             "log(x)",         "int",      "x*(log(x)-1)",                       "exact"],
		# Solve
		["Solve x^2-5x+6 = 0",      "x^2 - 5*x + 6",  "solve",    "{x=3,x=2}",                          "exact"],
		["Solve x^4-1 = 0",         "x^4 - 1",        "solve",    "{x=i,x=-i,x=1,x=-1}",                "exact"],
		["Solve x^2+1 = 0",         "x^2 + 1",        "solve",    "{x=i,x=-i}",                         "exact"],
		# ODE (formatting carries a 'depend' note; check the essentials).
		["Solve ODE y'=y",          "df(y,x) = y",    "ode",      "arbconst",                           "contains"],
		["Solve ODE y'=y has e^x",  "",               "",         "e^x",                                "carry"],
	]
	var last_text := ""
	for c in cases:
		var name: String = c[0]
		var mode: String = c[4]
		if mode == "carry":
			# Re-checks the previous result (e.g. ODE has BOTH arbconst and e^x).
			_assert(name, _normalize(last_text).contains(_normalize(c[3])),
				"got=%s" % _trim(last_text))
			continue
		_input.text = c[1]
		_main._do_op(c[2])
		var settled := await _await_no_pending()
		last_text = _last_history_output()
		var got := _normalize(last_text)
		var want := _normalize(c[3])
		var ok: bool
		if mode == "exact":
			ok = got == want
		else:
			ok = got.contains(want)
		_assert(name, settled and ok, "got=%s want=%s" % [_trim(last_text), c[3]])


# ----------------------------------------------------------------------------
# Phase B — breadth: every problem-library item evaluates without error.
# ----------------------------------------------------------------------------
func _phase_library_breadth() -> void:
	_log.append("\n## Phase B — problem library breadth (every item, no error)")
	var total := 0
	var ok_count := 0
	for cat_idx in range(ProblemLibrary.ALL.size()):
		var cat: Dictionary = ProblemLibrary.ALL[cat_idx]
		var items: Array = cat["items"]
		var cat_ok := 0
		var cat_total := 0
		for item_idx in range(items.size()):
			var item: Dictionary = items[item_idx]
			cat_total += 1
			total += 1
			var is_plot: bool = item.get("kind", "") == "plot"
			var hist_before: int = _history_box.get_child_count()
			_main._on_problem_selected(cat_idx, item_idx)
			var settled := await _await_no_pending()
			var good: bool
			if is_plot:
				# Plot items don't append history; success = engine settled.
				good = settled
			else:
				var added: bool = _history_box.get_child_count() > hist_before
				var text := _last_history_output()
				var errored: bool = text.contains("⚠") or text.strip_edges() == "" \
					or text.contains("*****")
				good = settled and added and not errored
			if good:
				cat_ok += 1
				ok_count += 1
			else:
				_log.append("   ❌ %s → %s  (%s)" % [
					cat["name"], item.get("label", "?"),
					_trim(_last_history_output())])
		_assert("%s — %d/%d items evaluated" % [cat["name"], cat_ok, cat_total],
			cat_ok == cat_total, "%d/%d ok" % [cat_ok, cat_total])
	_log.append("\n**Library breadth: %d/%d items returned a valid result.**"
		% [ok_count, total])


# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------
func _assert(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		_log.append("✅ %s%s" % [name, ("  — " + detail) if detail != "" else ""])
	else:
		_fail += 1
		_log.append("❌ %s%s" % [name, ("  — " + detail) if detail != "" else ""])
	_mark(("PASS " if ok else "FAIL ") + name)


## Reverse MathFormatter.to_display so engine answers can be compared as plain
## linear forms: Unicode superscripts → '^N', '·' → '*', and all whitespace
## removed. A leading run of superscripts gets a single inserted caret.
func _normalize(s: String) -> String:
	var out := ""
	var in_sup := false
	for ch in s:
		if _UNSUP.has(ch):
			if not in_sup:
				out += "^"
				in_sup = true
			out += _UNSUP[ch]
		else:
			in_sup = false
			out += ch
	out = out.replace("·", "*").replace("**", "^")
	out = out.replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")
	out = out.trim_suffix("$")
	# History rows prefix the result with the "= " display marker; drop it so
	# the bare expression can be compared.
	if out.begins_with("="):
		out = out.substr(1)
	return out


func _trim(s: String) -> String:
	return s.substr(0, 90).replace("\n", " | ")


func _await_no_pending(max_ms: int = 8000) -> bool:
	var deadline := Time.get_ticks_msec() + max_ms
	while _pending.size() > 0 and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.05).timeout
	return _pending.is_empty()


func _last_history_output() -> String:
	var n: int = _history_box.get_child_count()
	if n == 0:
		return ""
	var panel: Node = _history_box.get_child(n - 1)
	if panel.get_child_count() == 0:
		return ""
	var vb: Node = panel.get_child(0)
	if vb.get_child_count() < 2:
		return ""
	var out_label: RichTextLabel = vb.get_child(1) as RichTextLabel
	return "" if out_label == null else out_label.text


func _finish() -> void:
	var summary := "**%d passed / %d failed**  (of %d total)" % [
		_pass, _fail, _pass + _fail]
	var doc := "# Task 95 — Math-Function UI Test Report\n\n%s\n%s\n" % [
		summary, "\n".join(_log)]
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f:
		f.store_string(doc)
		f.close()
	_mark("DONE pass=%d fail=%d" % [_pass, _fail])
	print("MATHTEST_DONE pass=%d fail=%d" % [_pass, _fail])
	get_tree().quit()


func _mark(s: String) -> void:
	var f := FileAccess.open(
		MARKER,
		FileAccess.READ_WRITE if FileAccess.file_exists(MARKER) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("[%d] %s" % [Time.get_ticks_msec(), s])
	f.close()
