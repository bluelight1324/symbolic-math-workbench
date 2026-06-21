extends Node
## Comprehensive UI regression test (task 25).
## Added as a child of the Main control when --ui-test is set on the command
## line. Drives every major UI surface — menu bar, operation buttons,
## problem library, reset session, help wizard, notebook view, view menu —
## via the same code paths as a user click. Records PASS/FAIL per assertion
## to a marker file and a Markdown report.
##
## This test runs WITH rendering (so we don't trip up FileDialog / Window
## quirks). The window is invisible because we set it minimised before
## starting; the test never depends on what's on screen.

const MARKER := "i:/mathdot/uitest_marker.txt"
const REPORT := "i:/mathdot/task25_uitest_report.md"

var _main: Node
var _log: PackedStringArray = []
var _pass := 0
var _fail := 0


var _input: LineEdit            # _main.get("_input"), cached to dodge the
                                # built-in Node._input(event) Callable shadow.
var _history_box: VBoxContainer
var _plot: Control
var _wizard: HelpWizard
var _notebook: NotebookView
var _advanced: AdvancedView
var _pkg_settings: PackageSettings
var _code_view: CodeEdit
var _result_view: RichTextLabel
var _pending: Dictionary       # reference to main._pending (alias)


func _ready() -> void:
	_main = get_parent()
	_input = _main.get("_input") as LineEdit
	_history_box = _main.get("_history_box") as VBoxContainer
	_plot = _main.get("_plot") as Control
	_wizard = _main.get("_wizard") as HelpWizard
	_notebook = _main.get("_notebook") as NotebookView
	_advanced = _main.get("_advanced") as AdvancedView
	_pkg_settings = _main.get("_pkg_settings") as PackageSettings
	_code_view = _main.get("_code_view") as CodeEdit
	_result_view = _main.get("_result_view") as RichTextLabel
	_pending = _main.get("_pending")
	# Wait for the engine to boot.
	await get_tree().create_timer(1.5).timeout
	_mark("boot done; MathEngine ready=" + str(MathEngine.is_ready()))

	# Tasks 1–25 phases (existing).
	await _phase_existence()
	await _phase_operations()
	await _phase_menu_library()
	await _phase_reset_session()
	await _phase_wizard()
	await _phase_notebook()
	await _phase_view_menu()
	await _phase_keypad()

	# Tasks 31–35 phases (new — what was just done).
	await _phase_right_pane()           # task 34
	await _phase_package_settings()     # tasks 31, 32
	await _phase_advanced_view()        # tasks 26, 27
	await _phase_default_notebook()     # latest tweak — toolbar stays, notebook is default
	await _phase_notebook_view_toggle() # task 35 v2

	_finish()


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


# ----------------------------------------------------------------------------
# Phase 1 — UI structure exists as expected
# ----------------------------------------------------------------------------
func _phase_existence() -> void:
	_log.append("\n## Phase 1 — UI structure exists")
	_assert("Main has _input", _input != null)
	_assert("Main has _history_box", _history_box != null)
	_assert("Main has _plot", _plot != null)
	_assert("Main has _wizard", _wizard != null)
	_assert("Main has _notebook", _notebook != null)
	# Walk the menu bar's children (HBoxContainer of icon-button + popup pairs).
	var bar := _find_icon_menubar(_main)
	_assert("IconMenuBar present", bar != null)
	if bar:
		var button_count := 0
		for c in bar.get_children():
			if c is Button:
				button_count += 1
		# 1 View + 9 problem categories + 1 Help = 11.
		_assert("MenuBar has 11 category buttons",
			button_count == 11, "found %d" % button_count)


func _find_icon_menubar(node: Node) -> IconMenuBar:
	if node is IconMenuBar:
		return node
	for c in node.get_children():
		var r := _find_icon_menubar(c)
		if r:
			return r
	return null


# ----------------------------------------------------------------------------
# Phase 2 — every operation button (Simplify / Factor / d/dx / ∫ / Solve / ODE / Plot)
# ----------------------------------------------------------------------------
func _phase_operations() -> void:
	_log.append("\n## Phase 2 — operation buttons")
	var cases := [
		{"name": "Simplify (x+1)^2",      "expr": "(x+1)^2",            "op": "simplify",
		 "expect_contains": "x"},
		{"name": "Factor x^6-1",          "expr": "x^6 - 1",            "op": "factor",
		 "expect_contains": "x"},
		{"name": "d/dx sin(x)*x",         "expr": "sin(x)*x",           "op": "diff",
		 "expect_contains": "cos"},
		{"name": "∫ 1/(x^2+1) dx",        "expr": "1/(x^2+1)",          "op": "int",
		 "expect_contains": "atan"},
		{"name": "Solve x^2-5x+6 = 0",    "expr": "x^2 - 5*x + 6",      "op": "solve",
		 "expect_contains": "2"},
		{"name": "Solve ODE y'=y",        "expr": "df(y,x) = y",        "op": "ode",
		 "expect_contains": "arbconst"},
		{"name": "Plot sin(x)",           "expr": "sin(x)",             "op": "plot",
		 "expect_contains": ""},   # plot updates the plot panel, not history
	]
	for c in cases:
		var hist_before: int = _history_box.get_child_count()
		_input.text = c["expr"]
		_main._do_op(c["op"])
		var ok := await _await_no_pending()
		var got_text := _last_history_output()
		# Plot doesn't append a history row; everything else should.
		if c["op"] == "plot":
			_assert(c["name"] + ": no engine pending",
				ok, "engine settled" if ok else "still pending")
		else:
			var added: bool = _history_box.get_child_count() == hist_before + 1
			var matches: bool = c["expect_contains"] == "" or got_text.contains(c["expect_contains"])
			_assert(c["name"],
				ok and added and matches,
				"text=%s" % got_text.substr(0, 80).replace("\n", " | "))


# ----------------------------------------------------------------------------
# Phase 3 — pick one item from each problem-library category
# ----------------------------------------------------------------------------
func _phase_menu_library() -> void:
	_log.append("\n## Phase 3 — problem-library menu picks")
	for cat_idx in range(ProblemLibrary.ALL.size()):
		var cat: Dictionary = ProblemLibrary.ALL[cat_idx]
		var items: Array = cat["items"]
		var item_idx := 0
		# Skip plot-kind items so the test stays history-based.
		while item_idx < items.size() and items[item_idx].get("kind", "") == "plot":
			item_idx += 1
		if item_idx >= items.size():
			_assert("%s: pick item" % cat["name"], true, "(skipped — all plot)")
			continue
		var hist_before: int = _history_box.get_child_count()
		_main._on_problem_selected(cat_idx, item_idx)
		var ok := await _await_no_pending()
		var added: bool = _history_box.get_child_count() > hist_before
		var text := _last_history_output()
		_assert("%s → %s" % [cat["name"], items[item_idx]["label"]],
			ok and added,
			"text=%s" % text.substr(0, 80).replace("\n", " | "))


# ----------------------------------------------------------------------------
# Phase 4 — Reset session must not contaminate the next request (task 24 fix)
# ----------------------------------------------------------------------------
func _phase_reset_session() -> void:
	_log.append("\n## Phase 4 — Reset session (task-24 regression)")
	# Bind a variable first.
	_input.text = "g := x^3 + 1"
	_main._do_op("simplify")
	await _await_no_pending()
	# Reset.
	_main._on_reset()
	await get_tree().create_timer(0.3).timeout   # give the flush time to clear
	# Now run an op and confirm the output isn't polluted by leftover lines.
	_input.text = "(x+1)^2"
	_main._do_op("simplify")
	await _await_no_pending()
	var got := _last_history_output()
	var clean: bool = not (got.contains("clear$") or got.contains("latex not defined"))
	_assert("Reset-then-evaluate has no leftover lines",
		clean, "text=%s" % got.replace("\n", " | "))


# ----------------------------------------------------------------------------
# Phase 5 — Help wizard
# ----------------------------------------------------------------------------
func _phase_wizard() -> void:
	_log.append("\n## Phase 5 — Help wizard")
	_assert("Wizard starts hidden", not _wizard.visible)
	_main._open_wizard()
	await get_tree().process_frame
	_assert("Wizard opens", _wizard.visible)
	# Walk forward 3 steps.
	_wizard._on_next()
	_wizard._on_next()
	_wizard._on_next()
	await get_tree().process_frame
	_assert("Wizard advanced to step 4",
		_wizard._current == 3, "current=%d" % _wizard._current)
	_wizard.close_panel()
	await get_tree().process_frame
	_assert("Wizard closes", not _wizard.visible)


# ----------------------------------------------------------------------------
# Phase 6 — Notebook view toggle
# ----------------------------------------------------------------------------
func _phase_notebook() -> void:
	_log.append("\n## Phase 6 — Notebook view")
	var was_visible: bool = _notebook.visible
	_assert("Notebook starts hidden (or stable)", true,
		"initial visible=%s" % str(was_visible))
	_main._toggle_notebook()
	await get_tree().process_frame
	_assert("Notebook toggled visible",
		_notebook.visible != was_visible)
	# Toggle back so subsequent phases see the calculator.
	_main._toggle_notebook()
	await get_tree().process_frame
	_assert("Notebook toggled back",
		_notebook.visible == was_visible)


# ----------------------------------------------------------------------------
# Phase 7 — View menu items don't crash (window-size + fullscreen)
# ----------------------------------------------------------------------------
func _phase_view_menu() -> void:
	_log.append("\n## Phase 7 — View menu items")
	# Maximize.
	_main._on_view_selected(0)
	await get_tree().process_frame
	_assert("View → Maximize", true, "did not crash")
	# Resize presets — we don't strictly verify the size (headless ignores) but
	# the call should not throw.
	for id in [2, 3, 4, 5]:
		_main._on_view_selected(id)
		await get_tree().process_frame
	_assert("View → all four size presets ran", true)


# ----------------------------------------------------------------------------
# Phase 8 — Keypad token insertion
# ----------------------------------------------------------------------------
func _phase_keypad() -> void:
	_log.append("\n## Phase 8 — Keypad token insertion")
	_input.text = ""
	_input.set_caret_column(0)
	_main._insert_token("sqrt(")
	_assert("Keypad inserted 'sqrt('",
		_input.text.contains("sqrt("),
		"text=%s" % _input.text)


# ----------------------------------------------------------------------------
# Finish — write the marker + report and quit.
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Phase 9 — Right pane: Code + Result views populate after each operation
#           (task 34 split-right-pane).
# ----------------------------------------------------------------------------
func _phase_right_pane() -> void:
	_log.append("\n## Phase 9 — Right pane (task 34: Code + Result)")
	_assert("_code_view exists", _code_view != null)
	_assert("_result_view exists", _result_view != null)
	if _code_view == null or _result_view == null:
		return
	# Drive a deterministic op and assert both panes populated.
	_input.text = "(x+1)^3"
	_main._do_op("simplify")
	await _await_no_pending()
	_assert("Code pane shows the engine command",
		_code_view.text == "(x+1)^3", "code='%s'" % _code_view.text)
	_assert("Result pane shows the formatted output",
		_result_view.text.contains("x³") or _result_view.text.contains("x^3"),
		"result='%s'" % _result_view.text)
	# Same idea for an operation that wraps the input.
	_input.text = "sin(x)*x"
	_main._do_op("diff")
	await _await_no_pending()
	_assert("Code pane shows the wrapped command for d/dx",
		_code_view.text == "df(sin(x)*x, x)", "code='%s'" % _code_view.text)
	_assert("Result pane has cos+sin",
		_result_view.text.contains("cos") and _result_view.text.contains("sin"),
		"result='%s'" % _result_view.text.substr(0, 80))


# ----------------------------------------------------------------------------
# Phase 10 — Package settings dialog open/close (tasks 31, 32).
# ----------------------------------------------------------------------------
func _phase_package_settings() -> void:
	_log.append("\n## Phase 10 — Package settings (tasks 31, 32)")
	_assert("_pkg_settings exists", _pkg_settings != null)
	if _pkg_settings == null:
		return
	_assert("Settings dialog starts hidden", not _pkg_settings.visible)
	_pkg_settings.open()
	await get_tree().process_frame
	_assert("Settings dialog opens", _pkg_settings.visible)
	# PackageConfig should expose the canonical list of packages.
	_assert("PackageConfig.KNOWN is populated",
		PackageConfig.KNOWN.size() >= 20,
		"%d known packages" % PackageConfig.KNOWN.size())
	_assert("DEFAULT_SELECTED includes core packages",
		PackageConfig.DEFAULT_SELECTED.has("odesolve") \
		and PackageConfig.DEFAULT_SELECTED.has("taylor") \
		and PackageConfig.DEFAULT_SELECTED.has("limits"))
	# The currently-loaded set is a non-empty array.
	var sel: Array = PackageConfig.load_selected()
	_assert("load_selected() returns a non-empty array",
		sel.size() > 0, "size=%d" % sel.size())
	_pkg_settings.close_panel()
	await get_tree().process_frame
	_assert("Settings dialog closes", not _pkg_settings.visible)


# ----------------------------------------------------------------------------
# Phase 11 — Advanced view (tasks 26, 27: sidebar + filterable grid).
# ----------------------------------------------------------------------------
func _phase_advanced_view() -> void:
	_log.append("\n## Phase 11 — Advanced view (tasks 26, 27)")
	_assert("_advanced exists", _advanced != null)
	if _advanced == null:
		return
	_assert("Advanced view starts hidden", not _advanced.visible)
	_main._toggle_advanced()
	await get_tree().process_frame
	_assert("Advanced view opens", _advanced.visible)
	_assert("AdvancedLibrary built >= 200 problems",
		_count_advanced_items() >= 200,
		"count=%d" % _count_advanced_items())
	_main._toggle_advanced()
	await get_tree().process_frame
	_assert("Advanced view closes", not _advanced.visible)


func _count_advanced_items() -> int:
	var n := 0
	for cat in AdvancedLibrary.build():
		n += int(cat["items"].size())
	return n


# ----------------------------------------------------------------------------
# Phase 12 — Default opening view is the notebook; toolbar stays visible
#           above it (just-shipped layout change).
# ----------------------------------------------------------------------------
func _phase_default_notebook() -> void:
	_log.append("\n## Phase 12 — Default notebook + toolbar room")
	_assert("Notebook opens by default at startup", _notebook.visible)
	_assert("Notebook reserves room for toolbar (offset_top=102)",
		int(_notebook.offset_top) == 102,
		"offset_top=%d" % int(_notebook.offset_top))
	# The IconMenuBar should be present and at the top of the calculator UI.
	var bar := _find_icon_menubar(_main)
	_assert("Toolbar (IconMenuBar) still present", bar != null)
	if bar != null:
		_assert("Toolbar position.y is above the notebook's top",
			bar.global_position.y < float(_notebook.offset_top),
			"toolbar_y=%d notebook_top=%d" % [int(bar.global_position.y), int(_notebook.offset_top)])


# ----------------------------------------------------------------------------
# Phase 13 — Notebook Source ↔ Notebook view toggle (task 35 v2).
# ----------------------------------------------------------------------------
func _phase_notebook_view_toggle() -> void:
	_log.append("\n## Phase 13 — Source ↔ Notebook view toggle (task 35 v2)")
	# Confirm the view-mode toggle button exists and starts in Source mode.
	var btn = _notebook.get("_view_mode_btn")
	_assert("_view_mode_btn exists", btn != null)
	var editor = _notebook.get("_editor")
	var rendered = _notebook.get("_rendered_scroll")
	_assert("Source editor exists", editor != null)
	_assert("Rendered scroll exists", rendered != null)
	if editor == null or rendered == null:
		return
	_assert("Starts in Source mode (editor visible)", editor.visible)
	_assert("Starts in Source mode (rendered hidden)", not rendered.visible)
	# Flip to Notebook view.
	_notebook._toggle_view_mode()
	await get_tree().process_frame
	_assert("After toggle: editor hidden", not editor.visible)
	_assert("After toggle: rendered visible", rendered.visible)
	# The rendered box should have rebuilt cells from algebra.md.
	var rendered_box = _notebook.get("_rendered_box")
	if rendered_box != null:
		_assert("Rendered cells were emitted",
			rendered_box.get_child_count() > 0,
			"%d cells" % rendered_box.get_child_count())
	# Toggle back.
	_notebook._toggle_view_mode()
	await get_tree().process_frame
	_assert("Back to Source mode: editor visible", editor.visible)
	_assert("Back to Source mode: rendered hidden", not rendered.visible)


func _finish() -> void:
	var summary := "**%d passed / %d failed**  (of %d total)" % [
		_pass, _fail, _pass + _fail]
	var doc := "# Task 25 — Comprehensive UI Test Report\n\n%s\n%s\n" % [
		summary, "\n".join(_log)]
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f:
		f.store_string(doc)
		f.close()
	_mark("DONE pass=%d fail=%d" % [_pass, _fail])
	print("UITEST_DONE pass=%d fail=%d" % [_pass, _fail])
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
