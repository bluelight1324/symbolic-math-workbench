class_name NotebookView
extends Control
## File-backed notebook UI implementing P0–P2 from
## [task18_requirements.md](../task18_requirements.md).
##
## Layout:
##   [ sidebar: file tree ]  [ editor: CodeEdit on the open .md ]
##   [ status / action bar at bottom ]
##
## What's implemented in this view:
##   • P0 #1 workspace folder + sidebar (Tree)
##   • P0 #2 plain-Markdown notebook format with fenced blocks
##   • P0 #3 in-app editor (CodeEdit) — no syntax-highlight extension yet,
##     but fence-aware via NotebookRunner
##   • P0 #4 block runner via MathEngine
##   • P1 #5 content-addressed cache + provenance footer
##   • P1 #10 cas-test blocks with PASS/FAIL
##   • P1 #11 export (HTML; optional Pandoc shell-out if pandoc is on PATH)
##   • P2 #6 reactivity — partial: cache makes "Run Notebook" skip blocks
##     whose source hash matches their cached result. Full dependency-DAG
##     reactivity is deferred (see task19 doc).
##   • P2 #7 inline typeset math — partial: `cas-result` includes a LaTeX
##     line via REDUCE `rlfi` when the source asked for it; image rendering
##     of that LaTeX is deferred.
##   • P2 #8 step-by-step derivations — partial: `cas-derive` runs a fixed
##     pipeline (factor → expand → simplify) and lists intermediate forms.
##   • P2 #9 3D plots + animations — stubbed: `cas-plot3d` blocks are
##     recognised and produce a placeholder result; full 3D viewport
##     deferred.

const COL_BG := Color(0.08, 0.09, 0.11)
const COL_PANEL := Color(0.13, 0.14, 0.17)
const PAD := 12
const RADIUS := 8

var _workspace_dir: String = ""
var _open_file: String = ""

var _sidebar_tree: Tree
var _editor: CodeEdit
var _status: Label
var _path_label: Label
# Task 94 — MATLAB-style docked-panel title bars + their labels (recoloured by
# the active scheme; the editor title tracks the open file name).
var _sidebar_title_bar: PanelContainer
var _sidebar_title_lbl: Label
var _editor_title_bar: PanelContainer
var _editor_title_lbl: Label
var _status_bar: PanelContainer
var _file_dialog: FileDialog
var _open_file_dialog: FileDialog
var _new_name_dialog: AcceptDialog
var _new_name_input: LineEdit

# Task 35 — Mathematica-style inline rendering of the notebook with plots
# directly beneath their source. View toggle: source (CodeEdit) ↔ notebook
# (cell stack). `_plot_samples_by_line` is keyed by the cas-plot block's
# start-line in the parsed AST, populated when its result arrives, and used
# by the cell builder to draw the inline plot in the right place.
var _editor_container: Control
var _rendered_scroll: ScrollContainer
var _rendered_box: VBoxContainer
var _view_mode_btn: Button
# Task 58: notebook view is the primary display. Source is opt-in via the
# "Show Source" button. (Was `false` previously — see task 35 v2 doc.)
var _is_notebook_view: bool = true
var _plot_samples_by_line: Dictionary = {}    # int -> PackedFloat64Array

# Task 58 — persisted font preferences (family + size).
var _font_size: int = FontConfig.DEFAULT_SIZE
var _font_family: String = FontConfig.DEFAULT_FAMILY
var _font_resource: Font = null
var _font_family_btn: OptionButton
var _font_size_spin: SpinBox

# Task 60 — persisted colour scheme.
var _color_key: String = ColorConfig.DEFAULT_KEY
var _color_scheme: Dictionary = ColorConfig.scheme(ColorConfig.DEFAULT_KEY)
var _color_btn: OptionButton

# Task 61 — persisted density preset + shadow / animation toggles.
var _density_key: String = StyleConfig.DEFAULT_DENSITY
var _density: Dictionary = StyleConfig.density(StyleConfig.DEFAULT_DENSITY)
var _shadows_on: bool = true
var _animations_on: bool = true
var _density_btn: OptionButton
var _shadows_check: CheckBox
var _anim_check: CheckBox
var _root_bg: ColorRect    # the notebook view's background — re-coloured on scheme change

# Task 66 — single MenuButton replacing every action-bar widget.
var _menu_btn: MenuButton
var _popup: PopupMenu
var _font_submenu: PopupMenu
var _size_submenu: PopupMenu
var _theme_submenu: PopupMenu
var _style_submenu: PopupMenu
const _SIZE_OPTIONS := [10, 12, 14, 16, 18, 20, 22, 24, 28, 32]
const _ID_OPEN := 0
const _ID_NEW := 1
const _ID_SAVE := 2
const _ID_RUN := 3
const _ID_FORCE := 4
const _ID_EXPORT := 5
const _ID_VIEW := 6
const _ID_SHADOWS := 5000
const _ID_ANIMATIONS := 5001
const _ID_FONT_BASE := 1000
const _ID_SIZE_BASE := 2000
const _ID_THEME_BASE := 3000
const _ID_STYLE_BASE := 4000
const _ID_LOOKS_BASE := 6000

# Task 99 — plotting is now fully inline in the notebook cell stack; the old
# separate "plot strip below the editor" (task 35 v1) was removed.

# Async run state: while running, evaluate blocks one at a time so results
# correlate by FIFO. _pending[id] = {pair, new_kind, on_result: Callable}
var _pending: Dictionary = {}
var _run_queue: Array = []
var _run_results: Dictionary = {}  # block-index -> {new_kind, new_body}
var _run_blocks: Array = []
var _run_active := false


## Task 69 — exposed for main.gd so the global IconMenuBar can adopt this
## popup as its first category button.
func get_menu_popup() -> PopupMenu:
	return _popup


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	# Task 94 — a fresh install (no saved colour config yet) opens in the full
	# MATLAB look; returning users keep whatever they last chose.
	var first_run := not FileAccess.file_exists(ColorConfig.PATH)
	MathEngine.result_ready.connect(_on_engine_result)
	# Task 58 — load persisted font selection and apply it.
	_font_size = FontConfig.load_size()
	_font_family = FontConfig.load_family()
	_font_resource = FontConfig.font_resource(_font_family)
	if _font_size_spin:
		_font_size_spin.value = _font_size
	if _font_family_btn:
		_font_family_btn.select(FontConfig.family_index(_font_family))
	_apply_font()

	# Task 60 — load persisted colour scheme.
	_color_key = ColorConfig.load_key()
	_color_scheme = ColorConfig.scheme(_color_key)
	if _color_btn:
		_color_btn.select(ColorConfig.index_of(_color_key))
	# Task 61 — load persisted density + toggles.
	_density_key = StyleConfig.load_density()
	_density = StyleConfig.density(_density_key)
	_shadows_on = StyleConfig.load_shadows()
	_animations_on = StyleConfig.load_animations()
	if _density_btn:
		_density_btn.select(StyleConfig.index_of(_density_key))
	if _shadows_check:
		_shadows_check.button_pressed = _shadows_on
	if _anim_check:
		_anim_check.button_pressed = _animations_on
	_apply_visual_style()

	# Task 66 — reflect the loaded settings into the new MenuButton popup.
	_sync_menu_checks()

	# Task 58 — notebook view is the default; reflect in the toggle label.
	_apply_view_mode()

	# Task 94 — apply the bundled MATLAB look on first launch (after the UI and
	# all defaults are in place, so every constituent setting takes effect).
	if first_run:
		_apply_look("matlab")


func _build_ui() -> void:
	_root_bg = ColorRect.new()
	_root_bg.color = COL_BG
	_root_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root_bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, PAD)
	add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", PAD)
	margin.add_child(v)

	# Top bar: workspace path + actions.
	var topbar := HBoxContainer.new()
	topbar.add_theme_constant_override("separation", 8)
	v.add_child(topbar)
	_path_label = Label.new()
	_path_label.text = "(no workspace open)"
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar.add_child(_path_label)
	# Task 66 — every previous action-bar widget (Open workspace, New note,
	# Save, Run, Force re-run, Export HTML, Show Source, Font, Size, Theme,
	# Style, Shadows, Animations) lives in one PopupMenu now.
	# Task 69 — that popup is *hosted by the global IconMenuBar* on top of
	# the app (as its first category button). The notebook view's own
	# MenuButton has been removed from the action bar.
	_build_menubar_popup()

	# Split: sidebar | editor.
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 280
	v.add_child(split)

	# Task 94 — MATLAB "Current Folder" docked panel wrapping the file tree.
	var sidebar_col := VBoxContainer.new()
	sidebar_col.add_theme_constant_override("separation", 0)
	sidebar_col.custom_minimum_size = Vector2(240, 0)
	var sb_title := _make_title_bar("Current Folder")
	_sidebar_title_bar = sb_title[0]
	_sidebar_title_lbl = sb_title[1]
	sidebar_col.add_child(_sidebar_title_bar)
	split.add_child(sidebar_col)

	_sidebar_tree = Tree.new()
	_sidebar_tree.custom_minimum_size = Vector2(240, 0)
	_sidebar_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_tree.hide_root = false
	_sidebar_tree.allow_reselect = true
	# Task 68 §I-51 — long filenames truncate with an ellipsis instead of
	# clipping at the column edge.
	_sidebar_tree.columns = 1
	_sidebar_tree.column_titles_visible = false
	_sidebar_tree.item_activated.connect(_on_tree_item_activated)
	sidebar_col.add_child(_sidebar_tree)

	# Task 94 — editor column with a MATLAB-style title bar that shows the open
	# file name (like MATLAB's "Editor – name.md" docked tab).
	var editor_col := VBoxContainer.new()
	editor_col.add_theme_constant_override("separation", 0)
	editor_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var ed_title := _make_title_bar("Editor")
	_editor_title_bar = ed_title[0]
	_editor_title_lbl = ed_title[1]
	editor_col.add_child(_editor_title_bar)
	split.add_child(editor_col)

	# A container that holds both the raw source CodeEdit and the rendered
	# notebook view; only one is visible at a time (task 35 v2).
	_editor_container = Control.new()
	_editor_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_col.add_child(_editor_container)

	_editor = CodeEdit.new()
	_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_editor.draw_tabs = true
	_editor.gutters_draw_line_numbers = true
	_editor.scroll_smooth = true
	_editor.text = ""
	_editor_container.add_child(_editor)

	_rendered_scroll = ScrollContainer.new()
	_rendered_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rendered_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rendered_scroll.visible = false
	_editor_container.add_child(_rendered_scroll)
	# Task 68 §I-52 — cap the reading column at 1100 px so ultra-wide
	# displays don't render a half-meter-long line of text. A centring
	# CenterContainer would stretch the inner VBox; we wrap in a
	# MarginContainer that just maxes the inner width.
	var reading_wrap := HBoxContainer.new()
	reading_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rendered_scroll.add_child(reading_wrap)
	var left_pad := Control.new()
	left_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading_wrap.add_child(left_pad)
	_rendered_box = VBoxContainer.new()
	_rendered_box.add_theme_constant_override("separation", 12)
	_rendered_box.custom_minimum_size = Vector2(0, 0)
	_rendered_box.size_flags_horizontal = Control.SIZE_FILL
	# 1100 px is the cap; falls back to the parent width if narrower.
	_rendered_box.custom_minimum_size = Vector2(0, 0)
	_rendered_box.size_flags_stretch_ratio = 0.0
	# Use a fixed-width inner column via a sized Control wrapper.
	var inner := MarginContainer.new()
	inner.custom_minimum_size = Vector2(1100, 0)
	inner.add_child(_rendered_box)
	reading_wrap.add_child(inner)
	var right_pad := Control.new()
	right_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading_wrap.add_child(right_pad)

	# Task 99 — plots are rendered INLINE inside the notebook cell stack (see
	# _emit_block_cell), directly beneath the cas-plot block that produced them.
	# The old separate bottom "plot strip" / plotter pane was removed.

	# Status bar at the bottom — Task 94: a thin MATLAB-style status strip.
	_status_bar = PanelContainer.new()
	_status = Label.new()
	_status.text = "Ready"
	_status_bar.add_child(_status)
	v.add_child(_status_bar)

	# File dialogs (created once, reused).
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_file_dialog.dir_selected.connect(_on_workspace_chosen)
	add_child(_file_dialog)

	_new_name_dialog = AcceptDialog.new()
	_new_name_dialog.title = "New note"
	_new_name_input = LineEdit.new()
	_new_name_input.placeholder_text = "filename (without .md)"
	_new_name_input.custom_minimum_size = Vector2(360, 0)
	_new_name_dialog.add_child(_new_name_input)
	_new_name_dialog.confirmed.connect(_on_new_note_confirmed)
	add_child(_new_name_dialog)


# ============================================================================
# Workspace + file tree
# ============================================================================
func open_workspace(path: String) -> void:
	_workspace_dir = path
	_path_label.text = "Workspace: %s" % path
	_refresh_tree()
	_status.text = "Workspace opened"


func _refresh_tree() -> void:
	_sidebar_tree.clear()
	if _workspace_dir.is_empty():
		return
	var root := _sidebar_tree.create_item()
	root.set_text(0, _workspace_dir.get_file() + "/")
	_populate_tree(_workspace_dir, root)


func _populate_tree(dir_path: String, parent: TreeItem) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var entries: Array = []
	while true:
		var name := d.get_next()
		if name == "":
			break
		if name.begins_with(".") or name == ".cas-cache":
			continue
		entries.append(name)
	d.list_dir_end()
	entries.sort()
	for name in entries:
		var full := dir_path.path_join(name)
		var item := _sidebar_tree.create_item(parent)
		if DirAccess.dir_exists_absolute(full):
			item.set_text(0, name + "/")
			item.set_metadata(0, {"kind": "dir", "path": full})
			_populate_tree(full, item)
		elif name.ends_with(".md"):
			item.set_text(0, name)
			item.set_metadata(0, {"kind": "file", "path": full})


func _on_tree_item_activated() -> void:
	var sel := _sidebar_tree.get_selected()
	if sel == null:
		return
	var meta = sel.get_metadata(0)
	if meta is Dictionary and meta.get("kind") == "file":
		_open_file_at(meta["path"])


# ============================================================================
# File open/save
# ============================================================================
func _open_file_at(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_status.text = "Failed to open %s" % path
		return
	_editor.text = f.get_as_text()
	f.close()
	_open_file = path
	# Task 94 — MATLAB-style "Editor – name.md" title.
	if _editor_title_lbl:
		_editor_title_lbl.text = "Editor  –  %s" % path.get_file()
	_status.text = "Opened %s" % path
	# Plot samples belong to the previous file; drop them so stale inline plots
	# don't carry over.
	_plot_samples_by_line.clear()
	# Task 58 — stay in Notebook view (the primary display) on file open;
	# the user opts into raw Source via the "Show Source" toggle.
	_is_notebook_view = true
	_apply_view_mode()


func _on_save() -> void:
	if _open_file.is_empty():
		_status.text = "No file open to save"
		return
	var f := FileAccess.open(_open_file, FileAccess.WRITE)
	if f == null:
		_status.text = "Failed to write %s" % _open_file
		return
	f.store_string(_editor.text)
	f.close()
	_status.text = "Saved %s" % _open_file


func _on_open_workspace() -> void:
	_file_dialog.popup_centered_ratio(0.6)


func _on_workspace_chosen(dir: String) -> void:
	open_workspace(dir)


func _on_new_note() -> void:
	if _workspace_dir.is_empty():
		_status.text = "Open a workspace first"
		return
	_new_name_input.text = ""
	_new_name_dialog.popup_centered()
	_new_name_input.grab_focus()


func _on_new_note_confirmed() -> void:
	var raw := _new_name_input.text.strip_edges()
	if raw.is_empty():
		return
	if not raw.ends_with(".md"):
		raw += ".md"
	var path := _workspace_dir.path_join(raw)
	if FileAccess.file_exists(path):
		_status.text = "Already exists: %s" % path
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status.text = "Failed to create %s" % path
		return
	f.store_string("# %s\n\nWrite some prose, then a `cas` block:\n\n```cas\n(x+1)^2\n```\n")
	f.close()
	_refresh_tree()
	_open_file_at(path)


# ============================================================================
# Block runner — P0 #4, P1 #5/#10, P2 #6/#7/#8/#9
# ============================================================================
func _on_run() -> void:
	_run_internal(false)


## Force re-run — ignore the content-addressed cache and re-evaluate every
## block in the open file. Added in task 29 (the follow-up flagged at the end
## of task 28). Bound to the "Force re-run" toolbar button and to Ctrl+F5.
func _on_force_run() -> void:
	_run_internal(true)


func _run_internal(force: bool) -> void:
	if _open_file.is_empty():
		_status.text = "No file open"
		return
	if _run_active:
		_status.text = "Already running"
		return
	if not MathEngine.is_ready():
		_status.text = "Engine not ready"
		return
	# Make sure we save before running so the file on disk matches what we're
	# about to rewrite.
	_on_save()
	_run_blocks = NotebookRunner.parse_blocks(_editor.text)
	var pairs := NotebookRunner.pair_blocks(_run_blocks)
	_run_queue.clear()
	_run_results.clear()
	var cache_hits := 0
	for p in pairs:
		var src: Dictionary = p["source"]
		var src_hash := NotebookRunner.source_hash(src["body"], src["kind"])
		# Cache hit? Result block carries the same src-hash → skip — *unless*
		# the user asked for a force re-run.
		if not force and p["result"] != null:
			var existing_hash := NotebookRunner.extract_src_hash(p["result"]["body"])
			if existing_hash == src_hash:
				cache_hits += 1
				continue
		_run_queue.append({"pair": p, "src_hash": src_hash})
	if _run_queue.is_empty():
		_status.text = "All blocks cached — nothing to evaluate"
		return
	_run_active = true
	var note := "" if not force else "  (cache bypassed)"
	if force and cache_hits == 0 and pairs.size() > 0:
		# Cosmetic — no cached results existed anyway. Drop the "(cache bypassed)" note.
		note = ""
	_status.text = "Running 1/%d…%s" % [_run_queue.size(), note]
	_dispatch_next_block()


## Task 96 — execute a SINGLE cell (one source block, identified by its start
## line) on demand, reusing the same evaluation pipeline as "Run notebook" but
## with a one-entry queue. The cell's paired result is rewritten in place.
func _run_one(block_start: int) -> void:
	if _run_active:
		_status.text = "Already running"
		return
	if not MathEngine.is_ready():
		_status.text = "Engine not ready"
		return
	if _open_file.is_empty():
		_status.text = "No file open"
		return
	# Persist first so the on-disk text matches what we re-evaluate / rewrite.
	_on_save()
	_run_blocks = NotebookRunner.parse_blocks(_editor.text)
	var pairs := NotebookRunner.pair_blocks(_run_blocks)
	_run_queue.clear()
	_run_results.clear()
	for p in pairs:
		if int(p["source"]["start"]) == block_start:
			var src: Dictionary = p["source"]
			var src_hash := NotebookRunner.source_hash(src["body"], src["kind"])
			_run_queue.append({"pair": p, "src_hash": src_hash})
			break
	if _run_queue.is_empty():
		_status.text = "Cell not found"
		return
	_run_active = true
	_status.text = "Running this cell…"
	_dispatch_next_block()


func _dispatch_next_block() -> void:
	if _run_queue.is_empty():
		_finish_run()
		return
	var entry: Dictionary = _run_queue.front()
	var pair: Dictionary = entry["pair"]
	var src: Dictionary = pair["source"]
	var src_kind: String = src["kind"]
	var body: String = src["body"].strip_edges()
	var cmd: String
	match src_kind:
		NotebookRunner.KIND_CAS:
			cmd = body
		NotebookRunner.KIND_TEST:
			# Grammar: "assert: <lhs> = <rhs>"  →  evaluate the *difference*.
			# REDUCE auto-simplifies, so an equivalent pair evaluates to 0.
			# (`simplify(...)` isn't a built-in operator — REDUCE prompts for
			# a Y/N declaration if you call it, which would hang the engine.)
			var assertion := _parse_test(body)
			if assertion.is_empty():
				_finish_block_locally(entry, "BAD ASSERTION (use 'assert: <lhs> = <rhs>')", false)
				return
			cmd = "(%s) - (%s)" % [assertion["lhs"], assertion["rhs"]]
		NotebookRunner.KIND_DERIVE:
			# Pipeline of transformations stitched into one engine call. We
			# avoid `simplify()` (not a built-in operator in REDUCE — calling
			# it prompts for a Y/N declaration that would hang the engine).
			cmd = "%s; factorize(%s); trigsimp(%s, expand); trigsimp(%s, combine)" % [
				body, body, body, body]
		NotebookRunner.KIND_PLOT:
			# Same sampling cmd the calculator-mode plot uses (task 7).
			var x_min := -10.0
			var x_max := 10.0
			var n := 60
			var step := (x_max - x_min) / float(n)
			cmd = "on rounded; for i:=0:%d collect sub(x=(%f)+(i+0.5)*(%f), %s); off rounded" % [
				n, x_min, step, body]
		NotebookRunner.KIND_PLOT3D:
			# Stub for P2 #9: 3D viewport deferred. Report the request, but
			# don't evaluate a heavy 2D sample for it (would be misleading).
			_finish_block_locally(entry, "[3D plot deferred — request: %s]" % body, true)
			return
		_:
			_finish_block_locally(entry, "Unknown block kind: %s" % src_kind, false)
			return
	var id := MathEngine.evaluate(cmd)
	_pending[id] = entry


func _on_engine_result(id: int, output: String, is_error: bool) -> void:
	if not _pending.has(id):
		return
	var entry: Dictionary = _pending[id]
	_pending.erase(id)
	var pair: Dictionary = entry["pair"]
	var src_kind: String = pair["source"]["kind"]
	var ok := not is_error
	var payload := MathFormatter.to_display(output) if ok else MathFormatter.clean_error(output)
	if src_kind == NotebookRunner.KIND_PLOT and ok:
		# Task 35 / 99: store the samples by block start-line so the rendered
		# notebook view draws the plot INLINE directly beneath the cas-plot
		# block (see _emit_block_cell). No separate plot pane.
		var ys := MathFormatter.parse_number_list(output)
		_plot_samples_by_line[int(pair["source"]["start"])] = ys
		_finish_block_locally(entry, "plotted %d samples" % ys.size(), true)
		return
	if src_kind == NotebookRunner.KIND_TEST:
		var equiv := payload.strip_edges() == "0"
		_finish_block_locally(entry, "%s\nlhs - rhs → %s" % [
				("(verified)" if equiv else "(MISMATCH)"), payload], equiv)
		return
	if src_kind == NotebookRunner.KIND_DERIVE:
		# `output` is the concatenation of multiple replies on separate lines.
		var steps := output.split("\n")
		var formatted := PackedStringArray()
		var labels := ["evaluate", "factorize", "trig-expand", "trig-combine"]
		var k := 0
		for raw in steps:
			var t := raw.strip_edges().trim_suffix("$")
			if t.is_empty():
				continue
			formatted.append("%d. %s → %s" % [k + 1, labels[min(k, labels.size() - 1)], t])
			k += 1
		_finish_block_locally(entry, "\n".join(formatted), true)
		return
	_finish_block_locally(entry, payload, ok)


func _finish_block_locally(entry: Dictionary, payload: String, ok: bool) -> void:
	var pair: Dictionary = entry["pair"]
	var src_kind: String = pair["source"]["kind"]
	var result_kind: String
	match src_kind:
		NotebookRunner.KIND_CAS: result_kind = NotebookRunner.KIND_RESULT
		NotebookRunner.KIND_TEST: result_kind = NotebookRunner.KIND_TEST_RESULT
		NotebookRunner.KIND_DERIVE: result_kind = NotebookRunner.KIND_DERIVE_RESULT
		NotebookRunner.KIND_PLOT: result_kind = NotebookRunner.KIND_PLOT_RESULT
		NotebookRunner.KIND_PLOT3D: result_kind = NotebookRunner.KIND_PLOT3D_RESULT
		_: result_kind = "cas-result"
	var new_body := NotebookRunner.format_result_body(result_kind, entry["src_hash"], payload, ok)
	_run_results[pair["source"]["start"]] = {
		"pair": pair, "new_kind": result_kind, "new_body": new_body,
	}
	_run_queue.pop_front()
	if _run_queue.is_empty():
		_finish_run()
	else:
		_status.text = "Running %d/%d…" % [
			_run_results.size() + 1, _run_results.size() + _run_queue.size() + 1]
		_dispatch_next_block()


func _finish_run() -> void:
	_run_active = false
	var replacements: Array = _run_results.values()
	if replacements.is_empty():
		_status.text = "Done — nothing changed"
		# Even with all cached, switch to notebook view if there are plots
		# whose samples we already have, so the user sees them inline.
		if not _plot_samples_by_line.is_empty():
			_is_notebook_view = true
			_apply_view_mode()
		return
	var new_text := NotebookRunner.rewrite(_editor.text, replacements)
	_editor.text = new_text
	# Persist to disk so on-disk + on-screen stay in sync.
	_on_save()
	_status.text = "Done — %d block(s) updated" % replacements.size()
	# After a run, if any cas-plot blocks contributed samples, auto-switch to
	# the Mathematica-style notebook view so the plots appear inline.
	if not _plot_samples_by_line.is_empty():
		_is_notebook_view = true
		_apply_view_mode()
	elif _is_notebook_view:
		# Source text changed — rebuild the rendered cells from the new text.
		_rebuild_rendered_cells()


func _parse_test(body: String) -> Dictionary:
	# Accept the first non-empty line of the form: "assert: <lhs> = <rhs>"
	for raw in body.split("\n"):
		var line := raw.strip_edges()
		if not line.to_lower().begins_with("assert:"):
			continue
		var expr := line.substr(7).strip_edges()
		var eq := expr.find("=")
		if eq == -1:
			return {}
		return {"lhs": expr.substr(0, eq).strip_edges(), "rhs": expr.substr(eq + 1).strip_edges()}
	return {}


# ============================================================================
# Export (P1 #11) — HTML out of the box; Pandoc when available.
# ============================================================================
func _on_export_html() -> void:
	if _open_file.is_empty():
		_status.text = "Nothing to export"
		return
	var out_path := _open_file.get_basename() + ".html"
	var html := _markdown_to_html(_editor.text)
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		_status.text = "Failed to write %s" % out_path
		return
	f.store_string(html)
	f.close()
	_status.text = "Exported → %s" % out_path


## Plot x-range (the sampling grid the cas-plot command uses).
const X_MIN := -10.0
const X_MAX := 10.0


## Task 66 — build the menu's popup tree.
## Top-level items: file/run actions, then submenus for Font/Size/Theme/Style,
## then checkable items for Shadows/Animations.
## Task 69 — the popup is now a standalone PopupMenu that the global
## IconMenuBar attaches to its first button. The notebook view's own
## MenuButton is gone (see _build_ui).
func _build_menubar_popup() -> void:
	_popup = PopupMenu.new()
	add_child(_popup)
	_popup.clear()
	_popup.add_item("Open workspace…", _ID_OPEN)
	_popup.add_item("New note", _ID_NEW)
	_popup.add_separator()
	_popup.add_item("Save        Ctrl+S", _ID_SAVE)
	_popup.add_item("Run notebook       F5", _ID_RUN)
	_popup.add_item("Force re-run       Ctrl+F5", _ID_FORCE)
	_popup.add_item("Export HTML", _ID_EXPORT)
	_popup.add_separator()
	# View-mode toggle item — text refreshed by _apply_view_mode().
	_popup.add_item("Show Source", _ID_VIEW)
	_popup.add_separator()

	# Font submenu (23 families).
	_font_submenu = PopupMenu.new()
	_font_submenu.name = "FontMenu"
	for i in range(FontConfig.FAMILIES.size()):
		_font_submenu.add_radio_check_item(
			FontConfig.FAMILIES[i]["label"], _ID_FONT_BASE + i)
	_font_submenu.id_pressed.connect(_on_menu_id_pressed)
	_popup.add_child(_font_submenu)
	_popup.add_submenu_item("Font", "FontMenu")

	# Size submenu (discrete preset sizes).
	_size_submenu = PopupMenu.new()
	_size_submenu.name = "SizeMenu"
	for i in range(_SIZE_OPTIONS.size()):
		_size_submenu.add_radio_check_item(
			"%d pt" % int(_SIZE_OPTIONS[i]), _ID_SIZE_BASE + i)
	_size_submenu.id_pressed.connect(_on_menu_id_pressed)
	_popup.add_child(_size_submenu)
	_popup.add_submenu_item("Size", "SizeMenu")

	# Theme submenu (colour schemes).
	_theme_submenu = PopupMenu.new()
	_theme_submenu.name = "ThemeMenu"
	var theme_keys := ColorConfig.ordered_keys()
	for i in range(theme_keys.size()):
		_theme_submenu.add_radio_check_item(
			ColorConfig.scheme(theme_keys[i])["label"], _ID_THEME_BASE + i)
	_theme_submenu.id_pressed.connect(_on_menu_id_pressed)
	_popup.add_child(_theme_submenu)
	_popup.add_submenu_item("Theme", "ThemeMenu")

	# Style submenu (density presets).
	_style_submenu = PopupMenu.new()
	_style_submenu.name = "StyleMenu"
	var style_keys := StyleConfig.ordered_keys()
	for i in range(style_keys.size()):
		_style_submenu.add_radio_check_item(
			StyleConfig.density(style_keys[i])["label"], _ID_STYLE_BASE + i)
	_style_submenu.id_pressed.connect(_on_menu_id_pressed)
	_popup.add_child(_style_submenu)
	_popup.add_submenu_item("Style", "StyleMenu")

	_popup.add_separator()
	# Task 68 §J — "Looks" preset bundles.
	var looks_submenu := PopupMenu.new()
	looks_submenu.name = "LooksMenu"
	var look_keys := LooksConfig.ordered_keys()
	for i in range(look_keys.size()):
		looks_submenu.add_item(
			LooksConfig.get_look(look_keys[i])["label"], _ID_LOOKS_BASE + i)
	looks_submenu.id_pressed.connect(_on_menu_id_pressed)
	_popup.add_child(looks_submenu)
	_popup.add_submenu_item("Looks  ⭐", "LooksMenu")
	_popup.add_separator()
	_popup.add_check_item("Shadows", _ID_SHADOWS)
	_popup.add_check_item("Animations", _ID_ANIMATIONS)
	_popup.id_pressed.connect(_on_menu_id_pressed)


## Sync the radio-check marks in each submenu with the current settings.
func _sync_menu_checks() -> void:
	if _font_submenu:
		_check_only(_font_submenu, FontConfig.family_index(_font_family))
	if _size_submenu:
		var size_idx := _SIZE_OPTIONS.find(_font_size)
		if size_idx == -1:
			# Find nearest preset.
			var best := 0
			var best_d := 999
			for i in range(_SIZE_OPTIONS.size()):
				var d: int = abs(int(_SIZE_OPTIONS[i]) - _font_size)
				if d < best_d:
					best_d = d
					best = i
			size_idx = best
		_check_only(_size_submenu, size_idx)
	if _theme_submenu:
		_check_only(_theme_submenu, ColorConfig.index_of(_color_key))
	if _style_submenu:
		_check_only(_style_submenu, StyleConfig.index_of(_density_key))
	if _popup:
		var sidx := _popup.get_item_index(_ID_SHADOWS)
		if sidx >= 0:
			_popup.set_item_checked(sidx, _shadows_on)
		var aidx := _popup.get_item_index(_ID_ANIMATIONS)
		if aidx >= 0:
			_popup.set_item_checked(aidx, _animations_on)


func _check_only(menu: PopupMenu, sel: int) -> void:
	for i in range(menu.item_count):
		menu.set_item_checked(i, i == sel)


## Single handler dispatched by every top-level + submenu id_pressed signal.
func _on_menu_id_pressed(id: int) -> void:
	if id == _ID_OPEN:
		_on_open_workspace()
	elif id == _ID_NEW:
		_on_new_note()
	elif id == _ID_SAVE:
		_on_save()
	elif id == _ID_RUN:
		_on_run()
	elif id == _ID_FORCE:
		_on_force_run()
	elif id == _ID_EXPORT:
		_on_export_html()
	elif id == _ID_VIEW:
		_toggle_view_mode()
	elif id == _ID_SHADOWS:
		_shadows_on = not _shadows_on
		StyleConfig.save(_density_key, _shadows_on, _animations_on)
		_apply_visual_style()
		_sync_menu_checks()
	elif id == _ID_ANIMATIONS:
		_animations_on = not _animations_on
		StyleConfig.save(_density_key, _shadows_on, _animations_on)
		_sync_menu_checks()
	elif id >= _ID_FONT_BASE and id < _ID_SIZE_BASE:
		_on_font_family_changed(id - _ID_FONT_BASE)
		_sync_menu_checks()
	elif id >= _ID_SIZE_BASE and id < _ID_THEME_BASE:
		_font_size = int(_SIZE_OPTIONS[id - _ID_SIZE_BASE])
		FontConfig.save_pair(_font_size, _font_family)
		_apply_font()
		_sync_menu_checks()
	elif id >= _ID_THEME_BASE and id < _ID_STYLE_BASE:
		_on_color_changed(id - _ID_THEME_BASE)
		_sync_menu_checks()
	elif id >= _ID_STYLE_BASE and id < _ID_SHADOWS:
		_on_density_changed(id - _ID_STYLE_BASE)
		_sync_menu_checks()
	elif id >= _ID_LOOKS_BASE and id < _ID_LOOKS_BASE + 100:
		_apply_look(LooksConfig.ordered_keys()[id - _ID_LOOKS_BASE])


## Task 68 §J — apply a "Looks" preset: every constituent setting at once.
func _apply_look(key: String) -> void:
	var look: Dictionary = LooksConfig.get_look(key)
	# Theme
	_color_key = look["color"]
	_color_scheme = ColorConfig.scheme(_color_key)
	ColorConfig.save_key(_color_key)
	# Density
	_density_key = look["density"]
	_density = StyleConfig.density(_density_key)
	# Shadows / Animations
	_shadows_on = bool(look["shadows"])
	_animations_on = bool(look["animations"])
	StyleConfig.save(_density_key, _shadows_on, _animations_on)
	# Font family + size
	_font_family = String(look["font_family"])
	_font_resource = FontConfig.font_resource(_font_family)
	_font_size = int(look["font_size"])
	FontConfig.save_pair(_font_size, _font_family)
	_apply_font()
	_apply_visual_style()
	_sync_menu_checks()
	_status.text = "Look applied: %s" % look["label"]


## Task 60 — colour scheme handler.
func _on_color_changed(idx: int) -> void:
	var keys := ColorConfig.ordered_keys()
	if idx < 0 or idx >= keys.size():
		return
	_color_key = keys[idx]
	_color_scheme = ColorConfig.scheme(_color_key)
	ColorConfig.save_key(_color_key)
	_apply_visual_style()


## Task 61 — density / shadow / animation handlers.
func _on_density_changed(idx: int) -> void:
	var keys := StyleConfig.ordered_keys()
	if idx < 0 or idx >= keys.size():
		return
	_density_key = keys[idx]
	_density = StyleConfig.density(_density_key)
	StyleConfig.save(_density_key, _shadows_on, _animations_on)
	_apply_visual_style()


func _on_shadows_toggled(on: bool) -> void:
	_shadows_on = on
	StyleConfig.save(_density_key, _shadows_on, _animations_on)
	_apply_visual_style()


func _on_animations_toggled(on: bool) -> void:
	_animations_on = on
	StyleConfig.save(_density_key, _shadows_on, _animations_on)


## Apply the active scheme + density across the whole notebook view:
## background colour, cell spacing, rebuild cells with new bg/border/text.
func _apply_visual_style() -> void:
	if _root_bg:
		_root_bg.color = _color_scheme["bg"]
	if _rendered_box:
		_rendered_box.add_theme_constant_override(
			"separation", int(_density["cell_separation"]))
	# Task 94 — keep the chrome (title bars, tree, status) in step with the
	# scheme so the whole view stays cohesive (MATLAB-light by default).
	_apply_chrome_colors()
	if _is_notebook_view:
		_rebuild_rendered_cells()


## Task 58 — font controls (handlers + applier).
func _on_font_size_changed(v: float) -> void:
	_font_size = int(v)
	FontConfig.save_pair(_font_size, _font_family)
	_apply_font()


func _on_font_family_changed(idx: int) -> void:
	if idx < 0 or idx >= FontConfig.FAMILIES.size():
		return
	_font_family = FontConfig.FAMILIES[idx]["key"]
	_font_resource = FontConfig.font_resource(_font_family)
	FontConfig.save_pair(_font_size, _font_family)
	_apply_font()


## Apply the current font selection to the source editor, the sidebar Tree
## (task 63 — left panel font matches the overall font), the path / status
## labels, and — if currently in Notebook view — rebuild the rendered cells
## so their labels pick up the new size/family.
func _apply_font() -> void:
	# Editor
	if _editor:
		_editor.add_theme_font_size_override("font_size", _font_size)
		if _font_resource:
			_editor.add_theme_font_override("font", _font_resource)
		else:
			_editor.remove_theme_font_override("font")
	# Left-panel Tree — applies to every row.
	if _sidebar_tree:
		_sidebar_tree.add_theme_font_size_override("font_size", _font_size)
		if _font_resource:
			_sidebar_tree.add_theme_font_override("font", _font_resource)
		else:
			_sidebar_tree.remove_theme_font_override("font")
	# Status + workspace-path labels (chrome around the editor).
	for lbl in [_path_label, _status]:
		if lbl == null:
			continue
		lbl.add_theme_font_size_override("font_size", _font_size)
		if _font_resource:
			lbl.add_theme_font_override("font", _font_resource)
		else:
			lbl.remove_theme_font_override("font")
	if _is_notebook_view:
		_rebuild_rendered_cells()


## Apply the current font choice to one Label / RichTextLabel cell child.
## Heading sizes are bumped by 4/8 pt above the base.
func _font_apply(ctrl: Control, bump: int = 0) -> void:
	var size := _font_size + bump
	if ctrl is RichTextLabel:
		ctrl.add_theme_font_size_override("normal_font_size", size)
		if _font_resource:
			ctrl.add_theme_font_override("normal_font", _font_resource)
	elif ctrl is Label:
		ctrl.add_theme_font_size_override("font_size", size)
		if _font_resource:
			ctrl.add_theme_font_override("font", _font_resource)


## Task 35 v2 — Source ↔ Notebook view toggle. In Notebook mode, the editor
## is replaced by a scrollable column of cells built from the parsed AST:
## prose, source, result, and **plots inline** beneath the cas-plot block
## that produced them.
func _toggle_view_mode() -> void:
	_is_notebook_view = not _is_notebook_view
	_apply_view_mode()


func _apply_view_mode() -> void:
	if _editor == null or _rendered_scroll == null:
		return
	# Task 61 — optional fade between the two views.
	var incoming: Control = _rendered_scroll if _is_notebook_view else _editor
	var outgoing: Control = _editor if _is_notebook_view else _rendered_scroll
	if _animations_on:
		outgoing.visible = false
		incoming.visible = true
		incoming.modulate = Color(1, 1, 1, 0)
		var tween := create_tween()
		tween.tween_property(incoming, "modulate", Color(1, 1, 1, 1), 0.18)
	else:
		_editor.visible = not _is_notebook_view
		_rendered_scroll.visible = _is_notebook_view
		_editor.modulate = Color(1, 1, 1, 1)
		_rendered_scroll.modulate = Color(1, 1, 1, 1)
	if _view_mode_btn:
		# Task 58 — show the action, not the current mode, so the label
		# always says what clicking will do.
		_view_mode_btn.text = "Show Source" if _is_notebook_view else "Show Notebook"
	# Task 66 — update the View item label inside the MenuButton popup.
	if _popup:
		var view_idx := _popup.get_item_index(_ID_VIEW)
		if view_idx >= 0:
			_popup.set_item_text(view_idx,
				"Show Source" if _is_notebook_view else "Show Notebook")
	if _is_notebook_view:
		_rebuild_rendered_cells()


func _rebuild_rendered_cells() -> void:
	if _rendered_box == null:
		return
	for c in _rendered_box.get_children():
		c.queue_free()
	if _editor.text.is_empty():
		var empty := Label.new()
		empty.text = "(empty notebook)"
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		_rendered_box.add_child(empty)
		return
	# Walk the markdown into a flat sequence of cell descriptors.
	var lines := _editor.text.split("\n")
	var i := 0
	var prose_buf := PackedStringArray()
	var blocks := NotebookRunner.parse_blocks(_editor.text)
	var block_starts := {}
	for b in blocks:
		block_starts[int(b["start"])] = b
	var pairs := NotebookRunner.pair_blocks(blocks)
	var result_lines := {}   # start-line of result block -> true (so we skip emitting it as its own cell)
	for p in pairs:
		if p["result"] != null:
			result_lines[int(p["result"]["start"])] = true
	while i < lines.size():
		if block_starts.has(i):
			var b: Dictionary = block_starts[i]
			# Skip result-kind blocks — they're emitted alongside their
			# source above (or, if orphaned, would just clutter the view).
			if String(b["kind"]).ends_with("-result"):
				i = int(b["end"]) + 1
				continue
			# Flush any pending prose first.
			if prose_buf.size() > 0:
				_emit_prose_cell("\n".join(prose_buf))
				prose_buf = PackedStringArray()
			# Find this block's paired result (if any).
			var paired_result = null
			for p in pairs:
				if int(p["source"]["start"]) == i:
					paired_result = p["result"]
					break
			_emit_block_cell(b, paired_result)
			i = int(b["end"]) + 1
		elif result_lines.has(i):
			# Result block is emitted alongside its source above; skip its lines.
			# Advance to the closing fence.
			var j := i + 1
			while j < lines.size() and not lines[j].strip_edges().begins_with("```"):
				j += 1
			i = j + 1
		else:
			prose_buf.append(lines[i])
			i += 1
	if prose_buf.size() > 0:
		_emit_prose_cell("\n".join(prose_buf))


func _emit_prose_cell(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty():
		return
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("normal_font_size", _font_size)
	# Task 68 §C-20 + §C-22 — drop-cap on `# heading` paragraphs, smart-quote
	# substitution everywhere. Tiny markdown-ish rendering: # / ## headings,
	# otherwise paragraphs.
	# Task 96 — heading sizes scale with the (now doubled) base font instead of
	# fixed points, so headings stay larger than body text.
	var h2_size := _font_size + 6
	var h1_size := _font_size + 10
	var drop_size := _font_size + 18
	var converted := PackedStringArray()
	var first_h1 := true
	for line in t.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("## "):
			converted.append("[font_size=%d][b]%s[/b][/font_size]"
				% [h2_size, _smart_quotes(stripped.substr(3))])
		elif stripped.begins_with("# "):
			# Drop-cap: the first character of the very first H1 in a cell
			# gets a bump over the heading size.
			var headline := stripped.substr(2)
			if first_h1 and headline.length() > 0:
				first_h1 = false
				converted.append("[font_size=%d][b]%s[/b][/font_size][font_size=%d][b]%s[/b][/font_size]" % [
					drop_size, _smart_quotes(headline.substr(0, 1)),
					h1_size, _smart_quotes(headline.substr(1))])
			else:
				converted.append("[font_size=%d][b]%s[/b][/font_size]"
					% [h1_size, _smart_quotes(headline)])
		else:
			converted.append(_smart_quotes(line))
	lbl.text = "\n".join(converted)
	lbl.add_theme_color_override("default_color", _color_scheme["text"])
	_font_apply(lbl)
	_rendered_box.add_child(lbl)


## Task 68 §C-22 — smart-quote / em-dash / ellipsis substitution in prose.
## Conservative: only replace patterns that are *unambiguously* the typed
## ASCII shortcuts for the typographic glyph. Inline code segments (between
## backticks) are skipped so REDUCE syntax isn't mangled.
func _smart_quotes(s: String) -> String:
	# Split on backticks; only transform odd-indexed chunks (outside `code`).
	var parts := s.split("`")
	for i in range(parts.size()):
		if i % 2 == 1:
			continue   # inside a `code` segment
		var t: String = parts[i]
		t = t.replace("...", "…")
		t = t.replace("---", "—")
		t = t.replace("--", "—")
		# Simple curly quotes — leading space/start → opening, otherwise closing.
		var out := ""
		var prev := ""
		for ch in t:
			if ch == "\"":
				out += "“" if (prev == "" or prev == " " or prev == "\t" or prev == "\n") else "”"
			elif ch == "'":
				out += "‘" if (prev == "" or prev == " " or prev == "\t" or prev == "\n") else "’"
			else:
				out += ch
			prev = ch
		parts[i] = out
	return "`".join(parts)


func _emit_block_cell(block: Dictionary, paired_result) -> void:
	# Two stacked PanelContainers: source on top, result/plot below.
	# Tasks 60 + 61: all colours come from the active scheme, all paddings
	# / radii / border widths come from the active density preset.
	var src_panel := PanelContainer.new()
	src_panel.add_theme_stylebox_override("panel",
		_make_cell_box(_color_scheme["src_bg"], _color_scheme["src_border"]))
	# Task 68 §D-23 — hover state.
	_attach_hover(src_panel, _color_scheme["src_bg"], _color_scheme["src_border"])
	# Task 68 §D-27 — right-click → Copy / Re-run.
	_attach_cell_context_menu(src_panel, block["body"].strip_edges(), block["kind"])
	var src_v := VBoxContainer.new()
	src_v.add_theme_constant_override("separation", int(_density["chip_offset"]))
	src_panel.add_child(src_v)
	# Task 96 — chip label on the left, a per-cell ▶ Run button on the right, so
	# every source cell can be executed individually.
	var src_header := HBoxContainer.new()
	src_header.add_theme_constant_override("separation", 8)
	src_v.add_child(src_header)
	var src_kind_lbl := Label.new()
	src_kind_lbl.text = "▸ " + block["kind"]
	src_kind_lbl.add_theme_color_override("font_color", _color_scheme["src_chip"])
	src_kind_lbl.add_theme_font_size_override("font_size", int(_density["chip_size"]))
	src_header.add_child(src_kind_lbl)
	# Per-cell Run button, kept next to the chip (left-aligned) so it's always
	# visible regardless of the reading column's width.
	var run_btn := Button.new()
	run_btn.text = "▶ Run"
	run_btn.tooltip_text = "Run this cell"
	run_btn.focus_mode = Control.FOCUS_NONE
	run_btn.add_theme_font_size_override("font_size", int(_density["chip_size"]))
	var bstart := int(block["start"])
	run_btn.pressed.connect(func(): _run_one(bstart))
	src_header.add_child(run_btn)
	var hspacer := Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hspacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	src_header.add_child(hspacer)
	var src_text := RichTextLabel.new()
	src_text.bbcode_enabled = false
	src_text.fit_content = true
	src_text.scroll_active = false
	src_text.text = block["body"].strip_edges()
	src_text.add_theme_color_override("default_color", _color_scheme["text"])
	_font_apply(src_text)
	src_v.add_child(src_text)
	_rendered_box.add_child(src_panel)

	# Task 99 — plot rendered INLINE as a framed result cell directly beneath
	# the cas-plot source block, styled + coloured to match the notebook theme.
	if block["kind"] == NotebookRunner.KIND_PLOT \
			and _plot_samples_by_line.has(int(block["start"])):
		var ys: PackedFloat64Array = _plot_samples_by_line[int(block["start"])]
		var plot_cell := PanelContainer.new()
		plot_cell.add_theme_stylebox_override("panel",
			_make_cell_box(_color_scheme["res_bg"], _color_scheme["res_border"]))
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", int(_density["chip_offset"]))
		plot_cell.add_child(pv)
		var plot_chip := Label.new()
		plot_chip.text = "= plot   %s   (%d samples · x ∈ [%d, %d])" % [
			block["body"].strip_edges(), ys.size(), int(X_MIN), int(X_MAX)]
		plot_chip.add_theme_color_override("font_color", _color_scheme["res_chip"])
		plot_chip.add_theme_font_size_override("font_size", int(_density["chip_size"]))
		pv.add_child(plot_chip)
		var plot_panel := preload("res://scripts/plot_panel.gd").new()
		plot_panel.custom_minimum_size = Vector2(0, 260)
		plot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if plot_panel.has_method("set_theme_colors"):
			plot_panel.set_theme_colors(
				_color_scheme["src_bg"],                                   # plot bg
				_color_scheme["muted"],                                    # axes
				_color_scheme["muted"].lerp(_color_scheme["src_bg"], 0.6), # grid
				_color_scheme["src_border"])                               # curve
		pv.add_child(plot_panel)
		if plot_panel.has_method("set_samples"):
			plot_panel.set_samples(X_MIN, X_MAX, ys)
		_rendered_box.add_child(plot_cell)
		return

	if paired_result == null:
		return
	var res_panel := PanelContainer.new()
	res_panel.add_theme_stylebox_override("panel",
		_make_cell_box(_color_scheme["res_bg"], _color_scheme["res_border"]))
	_attach_hover(res_panel, _color_scheme["res_bg"], _color_scheme["res_border"])
	_attach_cell_context_menu(res_panel,
		NotebookRunner.payload_only(paired_result["body"]), "cas-result")
	var res_v := VBoxContainer.new()
	res_v.add_theme_constant_override("separation", int(_density["chip_offset"]))
	res_panel.add_child(res_v)
	var res_kind_lbl := Label.new()
	res_kind_lbl.text = "= result"
	res_kind_lbl.add_theme_color_override("font_color", _color_scheme["res_chip"])
	res_kind_lbl.add_theme_font_size_override("font_size", int(_density["chip_size"]))
	res_v.add_child(res_kind_lbl)
	var res_text := RichTextLabel.new()
	res_text.bbcode_enabled = false
	res_text.fit_content = true
	res_text.scroll_active = false
	res_text.text = NotebookRunner.payload_only(paired_result["body"])
	res_text.add_theme_color_override("default_color", _color_scheme["text"])
	_font_apply(res_text)
	res_v.add_child(res_text)
	_rendered_box.add_child(res_panel)


## Task 68 §D-23 — hover state. Brightens the cell's left-accent border on
## mouse-over and reverts on mouse-out. Cheap signal pair per cell; no Tween.
func _attach_hover(panel: PanelContainer, bg: Color, border: Color) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var hover_box := _make_cell_box(bg, border.lerp(Color.WHITE, 0.4))
	var base_box := panel.get_theme_stylebox("panel")
	panel.mouse_entered.connect(func():
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.add_theme_stylebox_override("panel", hover_box))
	panel.mouse_exited.connect(func():
		panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
		panel.add_theme_stylebox_override("panel", base_box))


## Task 68 §D-27 — right-click → small PopupMenu with Copy / Re-run actions.
func _attach_cell_context_menu(panel: PanelContainer, body: String, kind: String) -> void:
	panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT \
				and ev.pressed:
			var menu := PopupMenu.new()
			menu.add_item("Copy source")
			menu.add_separator()
			if kind != "cas-result" and kind != "cas-test-result" \
					and kind != "cas-derive-result" and kind != "cas-plot-result":
				menu.add_item("Re-run this block (Force re-run all)")
			add_child(menu)
			menu.id_pressed.connect(func(id):
				if id == 0:
					DisplayServer.clipboard_set(body)
					_status.text = "Copied: %s" % body.substr(0, 40).replace("\n", " ")
				elif id == 2:
					_on_force_run()
				menu.queue_free())
			menu.popup(Rect2i(Vector2i(ev.global_position), Vector2i(220, 0))))


## One StyleBoxFlat for a cell — colour / padding / corner radius / border
## thickness pull from the active scheme + density. Shadow is conditional on
## the user's checkbox.
## Task 94 — a MATLAB-style docked-panel title bar (grey strip + a thin bottom
## border). Returns [PanelContainer, Label]; both are recoloured per active
## scheme by _apply_chrome_colors().
func _make_title_bar(text: String) -> Array:
	var bar := PanelContainer.new()
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)   # task 96 — doubled
	bar.add_child(lbl)
	return [bar, lbl]


## Task 94 — derive a "chrome" (title-bar / status) fill from the scheme's
## background: a touch darker for light schemes, a touch lighter for dark ones.
func _chrome_fill() -> Color:
	var bg: Color = _color_scheme["bg"]
	return bg.darkened(0.10) if bg.get_luminance() > 0.5 else bg.lightened(0.12)


func _style_title_bar(bar: PanelContainer, lbl: Label) -> void:
	if bar == null:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = _chrome_fill()
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	box.border_width_bottom = 1
	box.border_color = _color_scheme["muted"]
	bar.add_theme_stylebox_override("panel", box)
	if lbl:
		lbl.add_theme_color_override("font_color", _color_scheme["text"])


## Task 94 — recolour every chrome element (title bars, sidebar tree, path /
## status labels, status strip) so the notebook view is cohesive with the
## active scheme — light & MATLAB-like by default, but correct for dark
## schemes too.
func _apply_chrome_colors() -> void:
	_style_title_bar(_sidebar_title_bar, _sidebar_title_lbl)
	_style_title_bar(_editor_title_bar, _editor_title_lbl)
	# Sidebar tree — white/dark panel matching the scheme, scheme-tinted select.
	if _sidebar_tree:
		var tree_box := StyleBoxFlat.new()
		tree_box.bg_color = _color_scheme["src_bg"]
		tree_box.set_content_margin_all(4)
		tree_box.set_border_width_all(1)
		tree_box.border_color = _color_scheme["muted"]
		_sidebar_tree.add_theme_stylebox_override("panel", tree_box)
		var sel := StyleBoxFlat.new()
		sel.bg_color = _color_scheme["src_border"].lerp(_color_scheme["bg"], 0.6)
		_sidebar_tree.add_theme_stylebox_override("selected", sel)
		_sidebar_tree.add_theme_stylebox_override("selected_focus", sel)
		_sidebar_tree.add_theme_color_override("font_color", _color_scheme["text"])
		_sidebar_tree.add_theme_color_override("font_selected_color", _color_scheme["text"])
	# Path + status labels.
	if _path_label:
		_path_label.add_theme_color_override("font_color", _color_scheme["text"])
	if _status:
		_status.add_theme_color_override("font_color", _color_scheme["muted"])
	# Status strip at the bottom — a thin MATLAB-style bar.
	if _status_bar:
		var sbar := StyleBoxFlat.new()
		sbar.bg_color = _chrome_fill()
		sbar.content_margin_left = 8
		sbar.content_margin_right = 8
		sbar.content_margin_top = 3
		sbar.content_margin_bottom = 3
		sbar.border_width_top = 1
		sbar.border_color = _color_scheme["muted"]
		_status_bar.add_theme_stylebox_override("panel", sbar)


func _make_cell_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(_density["corner_radius"]))
	sb.set_content_margin_all(int(_density["cell_padding"]))
	sb.border_color = border
	sb.border_width_left = int(_density["border_width"])
	if _shadows_on:
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 2)
	return sb


func _markdown_to_html(md: String) -> String:
	# Intentionally tiny converter: headings, code fences, paragraphs. Full
	# pandoc-quality output is out of scope here; for that the user can run
	# `pandoc note.md -o note.pdf` themselves (P1 #11 partial — see doc).
	var html := PackedStringArray()
	html.append("<!doctype html><meta charset='utf-8'><title>%s</title>" % _open_file.get_file())
	html.append("<style>body{font-family:system-ui,sans-serif;max-width:780px;margin:2em auto;color:#222} pre{background:#f2f2f4;padding:.7em;border-radius:6px;overflow:auto} .cas-result{background:#eef6ee;border-left:4px solid #6c6} .cas-test-result.PASS{background:#eef6ee;border-left:4px solid #6c6} .cas-test-result.FAIL{background:#fbecec;border-left:4px solid #c33}</style>")
	var lines := md.split("\n")
	var i := 0
	while i < lines.size():
		var line: String = lines[i]
		var stripped := line.strip_edges()
		if stripped.begins_with("```"):
			var kind := stripped.substr(3).strip_edges()
			var j := i + 1
			var body := PackedStringArray()
			while j < lines.size() and not lines[j].strip_edges().begins_with("```"):
				body.append(lines[j])
				j += 1
			var cls := ""
			var content := "\n".join(body).xml_escape()
			if kind.begins_with("cas"):
				cls = " class='%s'" % kind
				# Strip provenance footer for HTML display.
				content = NotebookRunner.payload_only("\n".join(body)).xml_escape()
				# Tag PASS/FAIL on test result blocks for styling.
				if kind == NotebookRunner.KIND_TEST_RESULT:
					var first := content.split("\n", false)[0].strip_edges() if content.length() > 0 else ""
					if first == "PASS":
						cls = " class='cas-test-result PASS'"
					elif first == "FAIL":
						cls = " class='cas-test-result FAIL'"
			html.append("<pre%s>%s</pre>" % [cls, content])
			i = j + 1
		elif stripped.begins_with("# "):
			html.append("<h1>%s</h1>" % stripped.substr(2).xml_escape())
			i += 1
		elif stripped.begins_with("## "):
			html.append("<h2>%s</h2>" % stripped.substr(3).xml_escape())
			i += 1
		elif stripped == "":
			i += 1
		else:
			# Group consecutive non-blank, non-fence, non-heading lines into one paragraph.
			var para := PackedStringArray()
			while i < lines.size():
				var s := lines[i].strip_edges()
				if s == "" or s.begins_with("```") or s.begins_with("# ") or s.begins_with("## "):
					break
				para.append(s)
				i += 1
			html.append("<p>%s</p>" % " ".join(para).xml_escape())
	return "\n".join(html)
