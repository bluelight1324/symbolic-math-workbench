extends Control
## Main UI for the Symbolic Math Workbench.
##
## Wires the persistent MathEngine autoload to a usable UI: input, operation
## buttons (Simplify, Factor, d/dx, ∫, Solve, Solve ODE, Plot), a scrolling
## history notebook, a keypad, parameter sliders, and a custom-drawn plot.

const PlotPanel := preload("res://scripts/plot_panel.gd")
const HelpWizardScript := preload("res://scripts/help_wizard.gd")
const NotebookViewScript := preload("res://scripts/notebook_view.gd")
const AdvancedViewScript := preload("res://scripts/advanced_view.gd")
const PackageSettingsScript := preload("res://scripts/package_settings.gd")

# --- design tokens (typography & spacing) ---
const COL_BG := Color(0.08, 0.09, 0.11)
const COL_PANEL := Color(0.13, 0.14, 0.17)
const COL_ACCENT := Color(0.20, 0.55, 0.95)
const COL_TEXT := Color(0.90, 0.92, 0.95)
const COL_ERR := Color(0.95, 0.45, 0.45)
const PAD := 16
const RADIUS := 10
# Larger type & taller buttons across the whole UI (task 9).
const FONT_BASE := 20
const FONT_TITLE := 28
const FONT_RESULT := 22
const BUTTON_MIN_H := 48
const INPUT_MIN_H := 56
const KEYPAD_MIN_H := 56

var _input: LineEdit
var _status: Label
var _error: Label
var _history_box: VBoxContainer
var _history_scroll: ScrollContainer
var _plot: Control
var _param_box: VBoxContainer
var _code_view: CodeEdit
var _result_view: RichTextLabel
var _wizard: HelpWizard
var _notebook: NotebookView
var _advanced: AdvancedView
var _pkg_settings: PackageSettings
var _icon_menubar: IconMenuBar    # task 69 — kept so we can add the Notebook
                                   # category to it after _notebook is created.
var _calc_root: Control

# per-request routing: id -> {kind, node}
var _pending := {}
# plotting state
var _plot_expr := ""
var _params := PackedStringArray()
var _param_values := {}
const X_MIN := -10.0
const X_MAX := 10.0
const SAMPLES := 200


func _ready() -> void:
	theme = _make_theme()
	_build_ui()
	# Open as large as possible — task 11.2.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	MathEngine.result_ready.connect(_on_result_ready)
	MathEngine.session_started.connect(func(): _set_status("Engine ready", false))
	MathEngine.session_failed.connect(func(r): _set_status(r, true))
	if MathEngine.is_ready():
		_set_status("Engine ready", false)
	else:
		_set_status("Starting engine…", false)

	# Demo mode: auto-run a differential-equation solve on startup. Enable with:
	#   <executable> --path app -- --demo-ode
	if OS.get_cmdline_user_args().has("--demo-ode") or OS.get_cmdline_args().has("--demo-ode"):
		MathEngine.session_started.connect(_run_ode_demo, CONNECT_ONE_SHOT)
		if MathEngine.is_ready():
			_run_ode_demo()

	# Menu demo: pick a handful of menu-bar problems so a headed launch shows
	# the catalogue end-to-end. Enable with:  -- --demo-menu
	if OS.get_cmdline_user_args().has("--demo-menu") or OS.get_cmdline_args().has("--demo-menu"):
		MathEngine.session_started.connect(_run_menu_demo, CONNECT_ONE_SHOT)
		if MathEngine.is_ready():
			_run_menu_demo()

	# Capture-only: take a screenshot after a short delay so the headed window
	# can be verified without an external screenshot tool. Enable with:
	#   -- --capture <path>
	var args := OS.get_cmdline_user_args()
	if "--capture" in args:
		var p := args.find("--capture")
		var out := "i:/readtgodot/app_screenshot_capture.png"
		if p + 1 < args.size():
			out = args[p + 1]
		# Longer delay when running the showcase / groebner demo, so the
		# evaluations actually finish before the screenshot fires.
		var delay := 2.5
		if "--showcase" in args:
			delay = 18.0
		elif "--demo-groebner" in args:
			delay = 12.0
		elif "--demo-plotnb" in args:
			delay = 8.0
		elif "--demo-task37" in args:
			delay = 14.0
		_save_screenshot_after(delay, out)

	# Notebook view (P0–P2 of the task-18 roadmap, implemented in task 19).
	_notebook = NotebookViewScript.new() as NotebookView
	add_child(_notebook)
	_notebook.visible = false
	# Task 69 — put the notebook menu as the FIRST button in the global
	# IconMenuBar at the top-left, styled like the other category buttons.
	# Reparents the notebook view's standalone PopupMenu into the IconMenuBar.
	if _icon_menubar:
		var notebook_popup := _notebook.get_menu_popup()
		if notebook_popup:
			# Detach from notebook before reparenting (avoids "already has parent" errors).
			if notebook_popup.get_parent():
				notebook_popup.get_parent().remove_child(notebook_popup)
			var nb_btn := _icon_menubar.add_category(
				"☰", "Notebook", notebook_popup, Color(0.55, 0.65, 0.95))
			_icon_menubar.move_child(nb_btn, 0)
	# Reserve room at the top for the IconMenuBar toolbar — the notebook view
	# is now the default opening pane (replacing the calculator's middle area),
	# but the toolbar above must stay visible and unchanged.
	# Toolbar layout: PAD(16) margin + 70px button row + PAD(16) separation ≈ 102.
	_notebook.offset_top = 102

	# Advanced problems view (task 26): a separate tab of hundreds of items.
	_advanced = AdvancedViewScript.new() as AdvancedView
	add_child(_advanced)
	_advanced.visible = false

	# Package-selection dialog (task 32) — choose which optional REDUCE
	# packages to load at engine start, persist via PackageConfig.
	_pkg_settings = PackageSettingsScript.new() as PackageSettings
	add_child(_pkg_settings)
	_pkg_settings.apply_requested.connect(_on_packages_applied)

	# Help wizard — attach as a top-level overlay and optionally auto-open.
	_wizard = HelpWizardScript.new() as HelpWizard
	add_child(_wizard)
	_wizard.set_steps(_help_steps())
	if "--tour" in args or OS.get_cmdline_args().has("--tour"):
		# Defer so the wizard's _ready has run and the main UI is fully laid out.
		_open_wizard.call_deferred()
	if "--notebook" in args or OS.get_cmdline_args().has("--notebook"):
		_open_notebook.call_deferred()
	if "--showcase" in args or OS.get_cmdline_args().has("--showcase"):
		_open_showcase_and_run.call_deferred()
	if "--ui-test" in args or OS.get_cmdline_args().has("--ui-test"):
		var t := preload("res://scripts/_uitest.gd").new()
		add_child(t)
	if "--advanced" in args or OS.get_cmdline_args().has("--advanced"):
		_toggle_advanced.call_deferred()
	if "--packages" in args or OS.get_cmdline_args().has("--packages"):
		_open_package_settings.call_deferred()
	if "--demo-plotnb" in args or OS.get_cmdline_args().has("--demo-plotnb"):
		_open_plot_notebook_and_run.call_deferred()
	if "--demo-task37" in args or OS.get_cmdline_args().has("--demo-task37"):
		_open_task37_and_run.call_deferred()
	if "--demo-popupmenu" in args or OS.get_cmdline_args().has("--demo-popupmenu"):
		_open_notebook_popupmenu_demo.call_deferred()
	if "--demo-fontdrop" in args or OS.get_cmdline_args().has("--demo-fontdrop"):
		# Tiny convenience flag: pre-select the Facebook font so the
		# screenshot shows the dropdown's new option highlighted.
		_open_font_dropdown_demo.call_deferred()
	if "--demo-groebner" in args or OS.get_cmdline_args().has("--demo-groebner"):
		# Make sure the groebner package is in the saved selection so
		# MathEngine.restart() loads it.
		var sel: Array = PackageConfig.load_selected()
		if not sel.has("groebner"):
			sel.append("groebner")
			PackageConfig.save_selected(sel)
		MathEngine.session_started.connect(_run_groebner_demo, CONNECT_ONE_SHOT)
		if MathEngine.is_ready():
			_run_groebner_demo()

	# Default opening view (task 35 follow-up): show the notebook as the
	# middle pane on every launch. The toolbar above stays visible. Specific
	# `--demo-*` / `--ui-test` / `--advanced` flags can still take over via
	# their own call_deferreds queued before this one.
	_open_notebook_default.call_deferred()


func _open_notebook_default() -> void:
	if _notebook == null:
		return
	if _notebook.visible:
		return    # something else (--notebook / --demo-plotnb / --showcase) got here first
	# Defer to _open_notebook so the sample workspace is loaded and algebra.md
	# is shown as the first opened file.
	_open_notebook()


func _run_groebner_demo() -> void:
	# Wait one frame so the autoload's _ready has settled, then dispatch a
	# pair of Gröbner-basis problems.
	await get_tree().process_frame
	_input.text = "groebner({x^2 + y^2 - 1, x - y}, {x, y})"
	_do_op("simplify")
	await get_tree().create_timer(1.0).timeout
	_input.text = "groebner({x^2 + y^2 - 1, x*y - 1}, {x, y})"
	_do_op("simplify")
	await get_tree().create_timer(1.0).timeout
	_input.text = "solve({x^2 + y^2 - 1, x - y}, {x, y})"
	_do_op("simplify")


func _open_wizard() -> void:
	if _wizard:
		_wizard.open()


func _open_notebook() -> void:
	if _notebook and not _notebook.visible:
		_toggle_notebook()
	# Auto-open algebra.md so a screenshot shows real content.
	var sample := "i:/readtgodot/app/notebooks_sample/algebra.md"
	if FileAccess.file_exists(sample):
		_notebook._open_file_at(sample)


func _open_notebook_popupmenu_demo() -> void:
	# Task 69 — the notebook popup now lives in the IconMenuBar. Find the
	# first child button of _icon_menubar (the Notebook button) and pop its
	# attached menu.
	if _icon_menubar == null:
		return
	await get_tree().create_timer(0.6).timeout
	for child in _icon_menubar.get_children():
		if child is Button:
			# IconMenuBar's _show_menu uses the same lookup, so simulate it.
			_icon_menubar.call("_show_menu", child)
			return


func _open_font_dropdown_demo() -> void:
	if _notebook == null:
		return
	await get_tree().create_timer(0.5).timeout
	# Pop the OptionButton so the dropdown items (including Facebook) are
	# visible in the screenshot.
	var btn = _notebook.get("_font_family_btn") as OptionButton
	if btn:
		btn.show_popup()


func _open_task37_and_run() -> void:
	if _notebook == null:
		return
	if not _notebook.visible:
		_toggle_notebook()
	var path := "i:/readtgodot/app/notebooks_sample/task37_system.md"
	if not FileAccess.file_exists(path):
		return
	_notebook._open_file_at(path)
	await get_tree().create_timer(1.5).timeout
	_notebook._on_force_run()


func _open_plot_notebook_and_run() -> void:
	if _notebook == null:
		return
	if not _notebook.visible:
		_toggle_notebook()
	var path := "i:/readtgodot/app/notebooks_sample/plotting.md"
	if not FileAccess.file_exists(path):
		return
	_notebook._open_file_at(path)
	await get_tree().create_timer(1.5).timeout
	_notebook._on_force_run()    # force, so any cached result still plots inline


func _open_showcase_and_run() -> void:
	if _notebook == null:
		return
	if not _notebook.visible:
		_toggle_notebook()
	var path := "i:/readtgodot/app/notebooks_sample/showcase.md"
	if not FileAccess.file_exists(path):
		return
	_notebook._open_file_at(path)
	# Give the engine a moment to finish booting, then run.
	await get_tree().create_timer(1.5).timeout
	_notebook._on_run()


# ----------------------------------------------------------------------------
# Help wizard step definitions (task 12)
# ----------------------------------------------------------------------------
func _help_steps() -> Array:
	return [
		{
			"title": "Welcome",
			"body": "Hi! This wizard walks you through every operation in the workbench.\n\n• Use [b]Next →[/b] / [b]← Back[/b] (or ← / → keys) to navigate.\n• Steps with a [b]▶ Try it[/b] button will run a live example.\n• Press [b]Esc[/b] or click [b]Close[/b] to exit any time.\n\nResults appear in the [b]History[/b] panel behind this dialog — close the wizard to inspect them in detail.",
		},
		{
			"title": "1. The input field",
			"body": "Type a math expression in the box at the top, e.g. [code](x+1)^2[/code] or [code]sin(x)*x[/code]. Press [b]Enter[/b] to evaluate as Simplify, or click one of the operation buttons.\n\nUse [code]^[/code] for powers, [code]*[/code] for multiplication, [code]df(f, x)[/code] for derivatives, [code]int(f, x)[/code] for integrals, [code]sqrt(...)[/code] for square roots, and constants [code]pi[/code], [code]e[/code], [code]i[/code].",
			"try": func(): _input.text = "(x+1)^2"; _input.grab_focus(),
		},
		{
			"title": "2. Simplify & Factor",
			"body": "[b]Simplify[/b] evaluates the expression as-is, expanding products and reducing fractions.\nExample: [code](x+1)^2[/code] → [code]x² + 2·x + 1[/code]\n\n[b]Factor[/b] returns factor / multiplicity pairs.\nExample: [code]x^6 - 1[/code] → [code]{{x²+x+1,1}, {x²-x+1,1}, {x+1,1}, {x-1,1}}[/code]",
			"try": func(): _input.text = "(x+1)^2"; _do_op("simplify"),
		},
		{
			"title": "3. Differentiate — d/dx",
			"body": "[b]d/dx[/b] wraps your expression as [code]df(<expr>, x)[/code] — the derivative with respect to x.\n\nExamples:\n• [code]sin(x)*x[/code] → [code]cos(x)·x + sin(x)[/code]\n• [code]x^x[/code] → [code]x^x·(log(x)+1)[/code]\n• [code]atan(x)[/code] → [code]1/(x²+1)[/code]",
			"try": func(): _input.text = "sin(x)*x"; _do_op("diff"),
		},
		{
			"title": "4. Integrate — ∫ dx",
			"body": "[b]∫ dx[/b] wraps your expression as [code]int(<expr>, x)[/code] — the indefinite integral with respect to x.\n\nExamples:\n• [code]1/(x^2+1)[/code] → [code]atan(x)[/code]\n• [code]log(x)[/code] → [code]x·(log(x) − 1)[/code]\n• [code]1/sqrt(1-x^2)[/code] → [code]asin(x)[/code]",
			"try": func(): _input.text = "1/(x^2+1)"; _do_op("int"),
		},
		{
			"title": "5. Solve — algebraic equations",
			"body": "[b]Solve[/b] wraps your expression as [code]solve(<expr>, x)[/code] — finds the roots assuming the expression equals 0. For systems, type the equations and variables yourself, e.g. [code]solve({x+y=3, x-y=1}, {x,y})[/code] and press Enter (Simplify).\n\nExamples:\n• [code]x^2 - 5*x + 6[/code] → [code]{x=3, x=2}[/code]\n• [code]x^4 - 1[/code] → [code]{x=i, x=-i, x=1, x=-1}[/code]\n• unsolvable quintics come back as [code]root_of(...)[/code] — that's correct, not an error.",
			"try": func(): _input.text = "x^2 - 5*x + 6"; _do_op("solve"),
		},
		{
			"title": "6. Solve ODE — differential equations",
			"body": "[b]Solve ODE[/b] wraps your input as [code]odesolve(<eq>, y, x)[/code]. Write the equation in terms of [code]y[/code] (as a function of [code]x[/code]) using [code]df(y,x)[/code] for y′ and [code]df(y,x,2)[/code] for y″.\n\nIntegration constants come back as [code]arbconst(n)[/code].\n\nExamples:\n• [code]df(y,x) = y[/code] → [code]y = e^x·C[/code]\n• [code]df(y,x,2) + y = 0[/code] → [code]y = C₁·sin(x) + C₂·cos(x)[/code] (SHM)",
			"try": func(): _input.text = "df(y,x) = y"; _do_op("ode"),
		},
		{
			"title": "7. Plot — sampled function graphs",
			"body": "[b]Plot[/b] samples your expression over x ∈ [−10, 10] and draws it in the right panel.\n\nIf the expression contains free single-letter symbols other than [code]x[/code] (e.g. [code]a[/code], [code]k[/code]), the app spawns a [b]slider[/b] for each parameter; drag the slider to re-plot live.\n\nTry the one-letter parameter [code]a[/code] in the example — a slider will appear above the plot.",
			"try": func(): _input.text = "sin(x) + a*cos(x)"; _do_op("plot"),
		},
		{
			"title": "8. Menu library — 72 preset problems",
			"body": "The menu bar at the top has [b]9 categories[/b]: Algebra, Calculus, Equations, ODEs, Matrices, Series, Trig, Numbers, Plots — with 72 ready-to-run problems between them. Pick one and the app loads it into the input field and runs it for you.\n\nGreat starting points to explore what the engine can do.",
			"try": func():
				# Pick a striking item: Algebra → Factor x^6 - 1.
				for i in range(ProblemLibrary.ALL.size()):
					if ProblemLibrary.ALL[i]["name"] == "Algebra":
						_on_problem_selected(i, 3)
						break,
		},
		{
			"title": "9. Keypad & shortcuts",
			"body": "The [b]keypad[/b] along the bottom inserts common tokens at the caret: digits, [code]^[/code], parentheses, [code]pi[/code], [code]sqrt([/code], [code]df([/code].\n\nKeyboard shortcuts:\n• [b]Enter[/b] in the input field = Simplify.\n• [b]F1[/b] reopens this wizard.\n• [b]F11[/b] toggles fullscreen.\n• [b]Esc[/b] exits fullscreen (or closes the wizard).",
			"try": func(): _insert_token("sqrt("),
		},
		{
			"title": "10. View menu & resizing",
			"body": "The window opens [b]maximized[/b]. Use the [b]View[/b] menu (first in the menu bar) to switch between Maximize, Fullscreen, or a preset size (Compact / Default / Large / Full HD), all centred on the current screen. You can also drag the window edges freely.\n\nF11 toggles fullscreen at any time.",
		},
		{
			"title": "11. History & Reset session",
			"body": "Every evaluation appears in the [b]History[/b] panel on the left. Click the [b]blue underlined input[/b] in any past entry to re-load that expression into the input field — handy for tweaking and re-running.\n\nThe engine session is [b]persistent[/b]: variables you bind (e.g. [code]f := x^2+1;[/code]) survive across evaluations. Use the [b]Reset session[/b] button in the header to clear all bindings and modes without restarting the app.",
		},
		{
			"title": "All set!",
			"body": "That's the whole tour. You can reopen this wizard any time with [b]F1[/b] or from the [b]Help[/b] menu.\n\nA full reference of every feature lives in the project docs (task1_…task12.md). Have fun exploring!",
		},
	]


var _menu_demo_done := false
## Capture the running window's viewport to PNG (used by demo modes so the
## headed run produces a verifiable artifact without external screenshot tools).
func _save_screenshot_after(delay_sec: float, out_path: String) -> void:
	await get_tree().create_timer(delay_sec).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_path)
	print("SCREENSHOT_SAVED ", out_path)


func _run_menu_demo() -> void:
	if _menu_demo_done:
		return
	_menu_demo_done = true
	_save_screenshot_after(3.0, "i:/readtgodot/app_screenshot_task11.png")
	# Pick one item from several different categories.
	const PICKS := [
		["Algebra", 3],     # Factor x^6 - 1
		["Calculus", 6],    # ∫ 1/(x^2+1) dx
		["Equations", 5],   # System x+y=3, x-y=1
		["Series", 4],      # limit sin(x)/x → 0
		["Numbers", 3],     # binomial(10,3)
		["Matrices", 1],    # det 3×3
	]
	for pick in PICKS:
		var cat_name: String = pick[0]
		var item_idx: int = pick[1]
		for i in range(ProblemLibrary.ALL.size()):
			if ProblemLibrary.ALL[i]["name"] == cat_name:
				_on_problem_selected(i, item_idx)
				break


var _demo_done := false
func _run_ode_demo() -> void:
	if _demo_done:
		return
	_demo_done = true
	for ode in ["df(y,x) = y", "df(y,x,2) + y = 0"]:
		_input.text = ode
		_do_op("ode")
	_input.text = "df(y,x) = 2*x*y"   # leave a fresh example in the field


# ----------------------------------------------------------------------------
# UI construction
# ----------------------------------------------------------------------------
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, PAD)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", PAD)
	margin.add_child(root)

	_build_menubar(root)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", PAD)
	root.add_child(header)
	var title := Label.new()
	title.text = "Symbolic Math Workbench"
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_status = Label.new()
	header.add_child(_status)
	var reset_btn := Button.new()
	reset_btn.text = "Reset session"
	reset_btn.custom_minimum_size = Vector2(0, BUTTON_MIN_H)
	reset_btn.pressed.connect(_on_reset)
	header.add_child(reset_btn)

	# Input row
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	root.add_child(input_row)
	_input = LineEdit.new()
	_input.placeholder_text = "Enter an expression, e.g.  (x+1)^2   or   sin(x)*x"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(0, INPUT_MIN_H)
	_input.text_submitted.connect(func(_t): _do_op("simplify"))
	input_row.add_child(_input)
	for op in [
		["Simplify", "simplify"], ["Factor", "factor"], ["d/dx", "diff"],
		["∫ dx", "int"], ["Solve", "solve"], ["Solve ODE", "ode"], ["Plot", "plot"],
	]:
		var b := Button.new()
		b.text = op[0]
		b.custom_minimum_size = Vector2(0, BUTTON_MIN_H)
		var kind: String = op[1]
		b.pressed.connect(func(): _do_op(kind))
		input_row.add_child(b)

	# Error line
	_error = Label.new()
	_error.add_theme_color_override("font_color", COL_ERR)
	_error.visible = false
	root.add_child(_error)

	# Split: history | plot
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 480
	root.add_child(split)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(380, 0)
	split.add_child(left)
	var hlabel := Label.new()
	hlabel.text = "History (click an input to reuse it)"
	left.add_child(hlabel)
	_history_scroll = ScrollContainer.new()
	_history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(_history_scroll)
	_history_box = VBoxContainer.new()
	_history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_history_box.add_theme_constant_override("separation", 8)
	_history_scroll.add_child(_history_box)

	# Right column — split vertically into a Code pane (top) and a Result+Plot
	# pane (bottom). Task 34: "the plot pane split into 2 — show code in one
	# and the results and plot if necessary the other one."
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	split.add_child(right)

	var right_split := VSplitContainer.new()
	right_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_split.split_offset = 200
	right.add_child(right_split)

	# --- top: Code pane ---
	var code_box := VBoxContainer.new()
	code_box.add_theme_constant_override("separation", 4)
	code_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_split.add_child(code_box)
	var code_label := Label.new()
	code_label.text = "Code  (engine command for the last operation)"
	code_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	code_box.add_child(code_label)
	_code_view = CodeEdit.new()
	_code_view.editable = false
	_code_view.scroll_smooth = true
	_code_view.draw_tabs = false
	_code_view.gutters_draw_line_numbers = false
	_code_view.placeholder_text = "(click an operation — the REDUCE command appears here)"
	_code_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_code_view.custom_minimum_size = Vector2(0, 120)
	_code_view.add_theme_font_size_override("font_size", FONT_RESULT)
	code_box.add_child(_code_view)

	# --- bottom: Result + Plot pane ---
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 4)
	result_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_split.add_child(result_box)

	var result_label := Label.new()
	result_label.text = "Result"
	result_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	result_box.add_child(result_label)
	_result_view = RichTextLabel.new()
	_result_view.bbcode_enabled = false
	_result_view.fit_content = true
	_result_view.scroll_active = true
	_result_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_view.custom_minimum_size = Vector2(0, 80)
	_result_view.add_theme_font_size_override("normal_font_size", FONT_RESULT)
	_result_view.text = ""
	result_box.add_child(_result_view)

	var plot_label := Label.new()
	plot_label.text = "Plot  (x ∈ [%d, %d])" % [int(X_MIN), int(X_MAX)]
	plot_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	result_box.add_child(plot_label)
	_param_box = VBoxContainer.new()
	result_box.add_child(_param_box)
	_plot = PlotPanel.new()
	_plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot.custom_minimum_size = Vector2(360, 200)
	result_box.add_child(_plot)

	# Keypad
	var keypad := GridContainer.new()
	keypad.columns = 9
	keypad.add_theme_constant_override("h_separation", 8)
	keypad.add_theme_constant_override("v_separation", 8)
	for tok in ["7", "8", "9", "^", "(", ")", "pi", "sqrt(", "df("]:
		var kb := Button.new()
		kb.text = tok
		kb.custom_minimum_size = Vector2(64, KEYPAD_MIN_H)
		kb.pressed.connect(func(): _insert_token(tok))
		keypad.add_child(kb)
	root.add_child(keypad)


## Build the menu bar: a View menu (window-size controls, task 11.2) followed
## by one PopupMenu per problem-library category.
## Visual menu bar (task 23): a row of icon-glyph buttons with tinted
## StyleBoxes and tooltips, each popping up its category's PopupMenu.
func _build_menubar(parent: Control) -> void:
	var bar := IconMenuBar.new()
	bar.custom_minimum_size = Vector2(0, 70)
	_icon_menubar = bar    # task 69 — exposed so the Notebook category can
	                        # be added after _notebook is created.

	# View — window-size + notebook toggle.
	var view_menu := PopupMenu.new()
	view_menu.add_item("Maximize", 0)
	view_menu.add_item("Toggle Fullscreen   (F11)", 1)
	view_menu.add_separator()
	view_menu.add_item("Compact   1100×680", 2)
	view_menu.add_item("Default   1300×720", 3)
	view_menu.add_item("Large   1600×900", 4)
	view_menu.add_item("Full HD   1920×1080", 5)
	view_menu.add_separator()
	view_menu.add_item("Open Notebook view…   (F2)", 6)
	view_menu.add_item("Open Advanced Problems…   (F3)", 7)
	view_menu.add_item("Engine packages…   (F4)", 8)
	view_menu.id_pressed.connect(_on_view_selected)
	bar.add_category("⊞", "View", view_menu, Color(0.55, 0.65, 0.95))

	# Each problem-library category gets its own icon-glyph + accent colour.
	var visuals := {
		"Algebra":  {"icon": "𝒂",  "accent": Color(0.95, 0.65, 0.45)},
		"Calculus": {"icon": "∫",  "accent": Color(0.55, 0.85, 0.55)},
		"Equations":{"icon": "=",  "accent": Color(0.55, 0.75, 0.95)},
		"ODEs":     {"icon": "𝑦′", "accent": Color(0.95, 0.55, 0.70)},
		"Matrices": {"icon": "▦",  "accent": Color(0.85, 0.65, 0.95)},
		"Series":   {"icon": "∑",  "accent": Color(0.95, 0.85, 0.45)},
		"Trig":     {"icon": "△",  "accent": Color(0.45, 0.85, 0.95)},
		"Numbers":  {"icon": "#",  "accent": Color(0.85, 0.55, 0.55)},
		"Plots":    {"icon": "↗",  "accent": Color(0.55, 0.95, 0.75)},
	}
	for cat_idx in range(ProblemLibrary.ALL.size()):
		var cat: Dictionary = ProblemLibrary.ALL[cat_idx]
		var menu := PopupMenu.new()
		var items: Array = cat["items"]
		for it_idx in range(items.size()):
			menu.add_item(items[it_idx]["label"], it_idx)
		var ci := cat_idx
		menu.id_pressed.connect(func(id): _on_problem_selected(ci, id))
		var spec: Dictionary = visuals.get(cat["name"], {
			"icon": cat["name"].substr(0, 1), "accent": Color(0.7, 0.7, 0.7),
		})
		bar.add_category(spec["icon"], cat["name"], menu, spec["accent"])

	# Help — always last.
	var help_menu := PopupMenu.new()
	help_menu.add_item("Open Tour   (F1)", 0)
	help_menu.id_pressed.connect(func(id):
		if id == 0:
			_open_wizard())
	bar.add_category("?", "Help", help_menu, Color(0.95, 0.45, 0.45))

	parent.add_child(bar)


func _on_view_selected(id: int) -> void:
	match id:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		1: _toggle_fullscreen()
		2: _set_window_size(1100, 680)
		3: _set_window_size(1300, 720)
		4: _set_window_size(1600, 900)
		5: _set_window_size(1920, 1080)
		6: _toggle_notebook()
		7: _toggle_advanced()
		8: _open_package_settings()


func _toggle_notebook() -> void:
	if _notebook == null:
		return
	_notebook.visible = not _notebook.visible
	if _notebook.visible:
		# Auto-open the bundled sample workspace on first switch.
		var sample := OS.get_executable_path().get_base_dir().path_join("notebooks_sample")
		if not DirAccess.dir_exists_absolute(sample):
			sample = "i:/readtgodot/app/notebooks_sample"   # dev fallback
		if DirAccess.dir_exists_absolute(sample):
			_notebook.open_workspace(sample)


func _toggle_advanced() -> void:
	if _advanced == null:
		return
	if _advanced.visible:
		_advanced.close_view()
	else:
		_advanced.open_view()


func _open_package_settings() -> void:
	if _pkg_settings:
		_pkg_settings.open()


func _on_packages_applied(_selected: Array) -> void:
	_set_status("Restarting engine with new packages…", false)
	MathEngine.restart()
	_set_status("Engine restarted", false)


func _set_window_size(w: int, h: int) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(w, h))
	# Centre the window on the current screen.
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var screen_pos := DisplayServer.screen_get_position(screen)
	DisplayServer.window_set_position(screen_pos + (screen_size - Vector2i(w, h)) / 2)


func _toggle_fullscreen() -> void:
	var m := DisplayServer.window_get_mode()
	if m == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_open_wizard()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			_toggle_notebook()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3:
			_toggle_advanced()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F4:
			_open_package_settings()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F5 and _notebook and _notebook.visible:
			if event.ctrl_pressed:
				_notebook._on_force_run()
			else:
				_notebook._on_run()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and event.ctrl_pressed and _notebook and _notebook.visible:
			_notebook._on_save()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			# Let the wizard own ESC when it's up.
			if _wizard and _wizard.visible:
				return
			var m := DisplayServer.window_get_mode()
			if m == DisplayServer.WINDOW_MODE_FULLSCREEN \
					or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
				get_viewport().set_input_as_handled()


## Run the problem picked from a menu: load its input into the field, then
## either evaluate the raw engine command or trigger the plot pipeline.
func _on_problem_selected(cat_idx: int, item_idx: int) -> void:
	var cat: Dictionary = ProblemLibrary.ALL[cat_idx]
	var item: Dictionary = cat["items"][item_idx]
	_clear_error()
	_input.text = item.get("input", "")
	if item.get("kind", "") == "plot":
		_start_plot(item["input"])
		return
	var cmd: String = item["cmd"]
	var label_node := _append_history(cat["name"].to_lower(), item["input"], cmd)
	var id := MathEngine.evaluate(cmd)
	_pending[id] = {"kind": "expr", "node": label_node}


func _make_theme() -> Theme:
	var t := Theme.new()
	# Larger default font size everywhere (task 9).
	t.default_font_size = FONT_BASE
	t.set_font_size("font_size", "Label", FONT_BASE)
	t.set_font_size("font_size", "Button", FONT_BASE)
	t.set_font_size("font_size", "LineEdit", FONT_BASE)
	t.set_font_size("normal_font_size", "RichTextLabel", FONT_RESULT)
	t.set_font_size("font_size", "PopupMenu", FONT_BASE)
	t.set_font_size("font_size", "MenuBar", FONT_BASE)

	var panel := StyleBoxFlat.new()
	panel.bg_color = COL_PANEL
	panel.set_corner_radius_all(RADIUS)
	panel.set_content_margin_all(12)
	t.set_stylebox("normal", "LineEdit", panel)

	var btn := StyleBoxFlat.new()
	btn.bg_color = COL_ACCENT.darkened(0.1)
	btn.set_corner_radius_all(RADIUS)
	btn.content_margin_left = 18
	btn.content_margin_right = 18
	btn.content_margin_top = 10
	btn.content_margin_bottom = 10
	t.set_stylebox("normal", "Button", btn)
	var btn_hover := btn.duplicate()
	btn_hover.bg_color = COL_ACCENT
	t.set_stylebox("hover", "Button", btn_hover)

	t.set_color("font_color", "Label", COL_TEXT)
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_color", "LineEdit", COL_TEXT)
	return t


# ----------------------------------------------------------------------------
# Operations
# ----------------------------------------------------------------------------
func _do_op(kind: String) -> void:
	var expr := _input.text.strip_edges()
	var problem := MathFormatter.validate(expr)
	if problem != "":
		_show_error(problem)
		return
	_clear_error()
	if kind == "plot":
		_start_plot(expr)
		return
	var cmd := expr
	match kind:
		"factor": cmd = "factorize(%s)" % expr
		"diff": cmd = "df(%s, x)" % expr
		"int": cmd = "int(%s, x)" % expr
		"solve": cmd = "solve(%s, x)" % expr
		"ode": cmd = "odesolve(%s, y, x)" % expr   # differential-equation solver
		_: cmd = expr   # simplify = evaluate as-is
	var label := _append_history(kind, expr, cmd)
	_show_code(cmd)
	if _result_view:
		_result_view.text = "…"
	var id := MathEngine.evaluate(cmd)
	_pending[id] = {"kind": "expr", "node": label}


func _start_plot(expr: String) -> void:
	_plot_expr = expr
	_params = MathFormatter.free_params(expr)
	_rebuild_param_sliders()
	_request_plot()


func _request_plot() -> void:
	if _plot_expr == "":
		return
	var step := (X_MAX - X_MIN) / float(SAMPLES)
	var psub := ""
	for name in _params:
		psub += ", %s=%f" % [name, float(_param_values.get(name, 1.0))]
	# Half-step offset on the sample grid so we never land exactly on x=0 (or
	# other clean integers), avoiding "0/0 formed" for functions with removable
	# singularities like sin(x)/x. The visual difference is imperceptible.
	var cmd := "on rounded; for i:=0:%d collect sub(x=(%f)+(i+0.5)*(%f)%s, %s); off rounded" % [
		SAMPLES, X_MIN, step, psub, _plot_expr]
	_show_code(cmd)
	var id := MathEngine.evaluate(cmd)
	_pending[id] = {"kind": "plot"}


func _rebuild_param_sliders() -> void:
	for c in _param_box.get_children():
		c.queue_free()
	for name in _params:
		if not _param_values.has(name):
			_param_values[name] = 1.0
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s =" % name
		lbl.custom_minimum_size = Vector2(40, 0)
		row.add_child(lbl)
		var slider := HSlider.new()
		slider.min_value = -5.0
		slider.max_value = 5.0
		slider.step = 0.1
		slider.value = float(_param_values[name])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val_lbl := Label.new()
		val_lbl.text = "%.1f" % float(_param_values[name])
		val_lbl.custom_minimum_size = Vector2(40, 0)
		var pname := name
		slider.value_changed.connect(func(v):
			_param_values[pname] = v
			val_lbl.text = "%.1f" % v
			_request_plot())
		row.add_child(slider)
		row.add_child(val_lbl)
		_param_box.add_child(row)


# ----------------------------------------------------------------------------
# Results
# ----------------------------------------------------------------------------
func _on_result_ready(id: int, output: String, is_error: bool) -> void:
	if not _pending.has(id):
		return
	var info: Dictionary = _pending[id]
	_pending.erase(id)
	if info["kind"] == "plot":
		if is_error:
			_show_error(MathFormatter.clean_error(output))
			_plot.clear_plot()
			_show_result(MathFormatter.clean_error(output), true)
			return
		var ys := MathFormatter.parse_number_list(output)
		_plot.set_samples(X_MIN, X_MAX, ys)
		_show_result("plotted %d samples" % ys.size(), false)
		return
	# expression result -> update its history entry AND the right-pane Result view.
	var label: RichTextLabel = info["node"]
	label.bbcode_enabled = false   # plain text; the RichTextLabel has no [sup] tag
	if is_error:
		label.add_theme_color_override("default_color", COL_ERR)
		label.text = MathFormatter.clean_error(output)
		_show_result(MathFormatter.clean_error(output), true)
	else:
		label.add_theme_color_override("default_color", COL_TEXT)
		var pretty: String = MathFormatter.to_display(output)
		label.text = "= " + pretty
		_show_result(pretty, false)


func _append_history(kind: String, expr: String, _cmd: String) -> RichTextLabel:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_corner_radius_all(RADIUS)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	panel.add_child(vb)

	var in_label := RichTextLabel.new()
	in_label.bbcode_enabled = true
	in_label.fit_content = true
	in_label.scroll_active = false
	in_label.meta_clicked.connect(func(_m): _input.text = expr; _input.grab_focus())
	in_label.text = "[color=#7fb2ff][url]%s[/url][/color]  [color=#8a8f99](%s)[/color]" % [expr, kind]
	vb.add_child(in_label)

	var out_label := RichTextLabel.new()
	out_label.bbcode_enabled = true
	out_label.fit_content = true
	out_label.scroll_active = false
	out_label.text = "…"
	vb.add_child(out_label)

	_history_box.add_child(panel)
	_scroll_to_bottom.call_deferred()
	return out_label


func _scroll_to_bottom() -> void:
	_history_scroll.scroll_vertical = int(_history_scroll.get_v_scroll_bar().max_value)


# ----------------------------------------------------------------------------
# Misc
# ----------------------------------------------------------------------------
func _insert_token(tok: String) -> void:
	_input.insert_text_at_caret(tok)
	_input.grab_focus()


func _on_reset() -> void:
	MathEngine.reset_session()
	_set_status("Session cleared", false)


# ----------------------------------------------------------------------------
# Right-pane writers (task 34): show the engine command and the latest result
# in the split-right view.
# ----------------------------------------------------------------------------
func _show_code(cmd: String) -> void:
	if _code_view:
		_code_view.text = cmd


func _show_result(text: String, is_err: bool) -> void:
	if _result_view == null:
		return
	_result_view.text = text
	_result_view.add_theme_color_override(
		"default_color", COL_ERR if is_err else COL_TEXT)


func _set_status(msg: String, is_err: bool) -> void:
	_status.text = msg
	_status.add_theme_color_override("font_color", COL_ERR if is_err else COL_TEXT)


func _show_error(msg: String) -> void:
	_error.text = "⚠ " + msg
	_error.visible = true


func _clear_error() -> void:
	_error.visible = false
