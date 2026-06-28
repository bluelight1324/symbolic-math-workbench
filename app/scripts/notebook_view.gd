class_name NotebookView
extends Control

## Task 115 — emitted whenever the rendered/source view flips, so the top-bar
## toggle button (owned by main.gd) can update its label.
signal view_mode_changed(is_notebook_view: bool)
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

## Task 129 — colour file names in the tree. Saturated hues chosen to read on
## both the light and dark MATLAB backgrounds; each notebook keeps a stable
## colour (hashed from its name), folders get a gold tint.
const _TREE_FILE_COLORS := [
	Color(0.00, 0.45, 0.85),   # blue
	Color(0.85, 0.33, 0.10),   # orange
	Color(0.20, 0.62, 0.28),   # green
	Color(0.58, 0.32, 0.78),   # purple
	Color(0.00, 0.58, 0.62),   # teal
	Color(0.82, 0.22, 0.45),   # rose
]
const _TREE_DIR_COLOR := Color(0.78, 0.60, 0.12)   # gold for folders

const COL_BG := Color(0.08, 0.09, 0.11)
const COL_PANEL := Color(0.13, 0.14, 0.17)
const PAD := 12
const RADIUS := 8

var _workspace_dir: String = ""
var _open_file: String = ""

var _sidebar_tree: Tree
var _sidebar_col: VBoxContainer   # task 126 — toggled by distraction-free mode
var _zen_on := false              # task 126 — distraction-free state
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
# src-hash (task 148.5 — stable across the run's text rewrite), populated when
# its result arrives, and used by the cell builder to draw the inline plot.
var _editor_container: Control
var _rendered_scroll: ScrollContainer
var _rendered_box: VBoxContainer
# (task 115 — the view toggle moved to the top IconMenuBar; see main.gd)
# Task 58: notebook view is the primary display. Source is opt-in via the
# "Show Source" button. (Was `false` previously — see task 35 v2 doc.)
var _is_notebook_view: bool = true
var _plot_samples_by_line: Dictionary = {}    # String(src-hash) -> PackedFloat64Array

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
const _ID_CLEAR := 7       # Task 126 — clear all cas-result outputs
const _ID_SEARCH := 8      # Task 126 — workspace search (req #13)
const _ID_ZEN := 9         # Task 126 — distraction-free mode (req #20)
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
	_font_resource = _resolve_bold_font(_font_family)
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
	# Task 115 — the Source/Notebook toggle now lives in the TOP IconMenuBar as a
	# proper category-style button (added by main.gd), matching the other top
	# buttons. The notebook view just emits view_mode_changed so that button's
	# label can follow the current mode.
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
	_sidebar_col = sidebar_col   # task 126 — distraction-free toggles this column
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
	root.set_custom_color(0, _TREE_DIR_COLOR)   # task 129 — coloured root folder
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
		# Task 123 — create a row ONLY for a directory or a .md notebook. Creating
		# the item before this check left non-notebook files (e.g. algebra.html)
		# as a blank, metadata-less row that couldn't be opened on click.
		if DirAccess.dir_exists_absolute(full):
			var item := _sidebar_tree.create_item(parent)
			item.set_text(0, name + "/")
			item.set_metadata(0, {"kind": "dir", "path": full})
			item.set_custom_color(0, _TREE_DIR_COLOR)   # task 129 — coloured folders
			_populate_tree(full, item)
		elif name.ends_with(".md"):
			var item := _sidebar_tree.create_item(parent)
			item.set_text(0, name)
			item.set_metadata(0, {"kind": "file", "path": full})
			# Task 129 — colour the notebook name (stable per filename).
			item.set_custom_color(0,
				_TREE_FILE_COLORS[abs(name.hash()) % _TREE_FILE_COLORS.size()])


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
	# Task 108 — the title placeholder was never substituted, so new notes
	# opened showing a literal "%s" heading. Use the note's name as the title.
	var title := raw.get_basename()
	f.store_string("# %s\n\nWrite some prose, then a `cas` block:\n\n```cas\n(x+1)^2\n```\n" % title)
	f.close()
	_refresh_tree()
	_open_file_at(path)
	# Task 108 — a brand-new note opens in editable Source mode (the rendered
	# notebook view is read-only), so the user can type into it immediately.
	_is_notebook_view = false
	_apply_view_mode()


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
			# Task 126 — accept LaTeX/MathJax in a cas block (no-op for plain
			# REDUCE source, which has no backslash).
			cmd = _latex_to_reduce(body)
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
			var n := 120   # task 136 — finer sampling → smoother, clearer curve
			var step := (x_max - x_min) / float(n)
			cmd = "on rounded; for i:=0:%d collect sub(x=(%f)+(i+0.5)*(%f), %s); off rounded" % [
				n, x_min, step, body]
		NotebookRunner.KIND_PLOT3D:
			# Task 126 (req #9) — real inline 3D surface. The mesh is built at
			# render time from the block body (sampled with Godot's Expression
			# evaluator); here we just record that it rendered.
			_finish_block_locally(entry, "3D surface rendered inline (%s)" % body, true)
			return
		NotebookRunner.KIND_SURFACE:
			# Task 148.6 — parametric (u,v) surface, also built at render time.
			_finish_block_locally(entry, "parametric surface rendered inline (%s)" % body, true)
			return
		_:
			_finish_block_locally(entry, "Unknown block kind: %s" % src_kind, false)
			return
	var id := MathEngine.evaluate(cmd)
	_pending[id] = entry
	_watch_block_timeout(id)


## Task 114 — guard against a block whose evaluation never returns. A heavy
## command (e.g. `int(exp(-x^2), x)`) can make REDUCE hit "insufficient
## freestore", so the sentinel that ends the reply never arrives and the result
## signal never fires. Without this the run would stay `_run_active = true`
## forever — which makes EVERY later Run (cell or notebook) silently early-out
## with "Already running". On timeout we abort the run, reset the state, and
## restart the (stuck) engine so the app stays usable.
func _watch_block_timeout(id: int) -> void:
	await get_tree().create_timer(20.0).timeout
	if not _run_active or not _pending.has(id):
		return    # block completed normally (or run already aborted)
	_pending.clear()
	_run_queue.clear()
	_run_results.clear()
	_run_active = false
	_status.text = "⚠ Run timed out — the engine was restarted. Press Run again."
	MathEngine.restart()


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
		# Task 148.5 — key by the block's src-hash (stable), not its start line,
		# which shifts when the run rewrites the text with result blocks inserted.
		_plot_samples_by_line[entry["src_hash"]] = ys
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
		NotebookRunner.KIND_SURFACE: result_kind = NotebookRunner.KIND_SURFACE_RESULT
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


# ============================================================================
# Task 126 — remaining-feature implementations
# ============================================================================

## Clear every *-result block (cas-result, cas-test-result, cas-plot-result, …)
## from the open notebook so the next Run recomputes from clean. Closes the
## task-122 gap (Force re-run overwrote results; this empties them).
func _on_clear_outputs() -> void:
	if _open_file.is_empty():
		_status.text = "No file open"
		return
	_editor.text = _strip_result_blocks(_editor.text)
	_on_save()
	if _is_notebook_view:
		_rebuild_rendered_cells()
	_status.text = "Cleared all outputs — Run to recompute"


## Pure helper (testable) — remove every *-result fenced block from notebook text.
func _strip_result_blocks(text: String) -> String:
	var out := PackedStringArray()
	var skipping := false
	for line in text.split("\n"):
		var s := line.strip_edges()
		if not skipping and s.begins_with("```") \
				and s.substr(3).strip_edges().ends_with("-result"):
			skipping = true
			continue                     # drop the opening fence
		if skipping:
			if s == "```":
				skipping = false         # drop the closing fence and stop
			continue
		out.append(line)
	return "\n".join(out)


## Distraction-free mode (requirement #20) — hide the file-tree sidebar so the
## editor/notebook gets the full width. Toggle again to restore.
func _toggle_distraction_free() -> void:
	_zen_on = not _zen_on
	if _sidebar_col:
		_sidebar_col.visible = not _zen_on
	if _popup:
		var i := _popup.get_item_index(_ID_ZEN)
		if i >= 0:
			_popup.set_item_checked(i, _zen_on)
	_status.text = "Distraction-free: %s" % ("on" if _zen_on else "off")


## Workspace search (requirement #13) — recursively grep every .md notebook in
## the workspace for a substring and list matches; clicking a hit opens that
## notebook at the matching line.
var _search_dialog: AcceptDialog
var _search_input: LineEdit
var _search_results: ItemList
var _search_hits: Array = []

func _on_search_workspace() -> void:
	if _workspace_dir.is_empty():
		_status.text = "No workspace open"
		return
	if _search_dialog == null:
		_search_dialog = AcceptDialog.new()
		_search_dialog.title = "Search workspace"
		_search_dialog.min_size = Vector2(560, 460)
		var box := VBoxContainer.new()
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_search_input = LineEdit.new()
		_search_input.placeholder_text = "search text…"
		_search_input.text_submitted.connect(func(_t): _run_workspace_search())
		box.add_child(_search_input)
		_search_results = ItemList.new()
		_search_results.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_search_results.custom_minimum_size = Vector2(540, 380)
		_search_results.item_activated.connect(_on_search_result_activated)
		box.add_child(_search_results)
		_search_dialog.add_child(box)
		add_child(_search_dialog)
	_search_input.text = ""
	_search_results.clear()
	_search_hits.clear()
	_search_dialog.popup_centered()
	_search_input.grab_focus()


func _run_workspace_search() -> void:
	var needle := _search_input.text.strip_edges()
	_search_results.clear()
	_search_hits.clear()
	if needle.is_empty():
		return
	var files: Array = []
	_collect_md_files(_workspace_dir, files)
	var low := needle.to_lower()
	for path in files:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var ln := 0
		while not f.eof_reached():
			var line := f.get_line()
			ln += 1
			if line.to_lower().find(low) != -1:
				_search_hits.append({"path": path, "line": ln})
				_search_results.add_item("%s:%d  %s" % [
					path.get_file(), ln, line.strip_edges().left(60)])
		f.close()
	if _search_hits.is_empty():
		_search_results.add_item("(no matches)")


func _collect_md_files(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	while true:
		var name := d.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full := dir_path.path_join(name)
		if DirAccess.dir_exists_absolute(full):
			_collect_md_files(full, out)
		elif name.ends_with(".md"):
			out.append(full)
	d.list_dir_end()


func _on_search_result_activated(idx: int) -> void:
	if idx < 0 or idx >= _search_hits.size():
		return
	var hit: Dictionary = _search_hits[idx]
	_open_file_at(hit["path"])
	if not _is_notebook_view and _editor:
		var l: int = int(hit["line"]) - 1
		if l >= 0 and l < _editor.get_line_count():
			_editor.set_caret_line(l)
			_editor.center_viewport_to_caret()
	_search_dialog.hide()


## Wikilink click (requirement #12) — `[[Note]]` in prose opens Note.md from the
## workspace (creating nothing; just navigates if it exists).
func _on_prose_meta_clicked(meta) -> void:
	var name := str(meta)
	if not name.ends_with(".md"):
		name += ".md"
	var target := _workspace_dir.path_join(name)
	if FileAccess.file_exists(target):
		_open_file_at(target)
		_status.text = "Opened %s" % name
	else:
		_status.text = "No such note: %s" % name


## LaTeX → REDUCE input conversion (requirements from tasks 121/124). Translates
## a useful subset of LaTeX/MathJax to REDUCE syntax so a `cas` block can be
## written in LaTeX. No-op unless the source actually contains a backslash, so
## existing plain-REDUCE blocks are never touched.
func _latex_to_reduce(src: String) -> String:
	# No-op unless the source actually looks like LaTeX. A backslash command OR a
	# brace super/subscript (`^{` / `_{`, which REDUCE never writes) is the signal;
	# plain REDUCE — including list syntax like {1,2,3} — is left untouched.
	if src.find("\\") == -1 and src.find("^{") == -1 and src.find("_{") == -1:
		return src
	var s := src
	# \int_{a}^{b} BODY \, dVAR   →   int(BODY, VAR, a, b)
	var re_int := RegEx.new()
	# …(body)… then a separator (\, or whitespace), then `d<var>` as a whole word.
	# The separator + word-boundary stop the `d` inside e.g. \cdot from matching.
	re_int.compile("\\\\int_\\{([^}]*)\\}\\^\\{([^}]*)\\}(.*?)(?:\\\\,|\\s)\\s*d\\s*([A-Za-z])\\b")
	var m := re_int.search(s)
	while m != null:
		var lo := _latex_to_reduce(m.get_string(1))
		var hi := _latex_to_reduce(m.get_string(2))
		var bodye := _latex_to_reduce(m.get_string(3)).strip_edges()
		var v := m.get_string(4)
		s = s.substr(0, m.get_start()) + "int(%s, %s, %s, %s)" % [bodye, v, lo, hi] \
			+ s.substr(m.get_end())
		m = re_int.search(s)
	# ^{...} → ^(...) FIRST, so a nested superscript inside a \frac / \sqrt becomes
	# brace-free; the (non-nesting) \frac / \sqrt regexes can then match.
	var re_sup := RegEx.new()
	re_sup.compile("\\^\\{([^{}]*)\\}")
	m = re_sup.search(s)
	while m != null:
		s = s.substr(0, m.get_start()) + "^(%s)" % m.get_string(1) + s.substr(m.get_end())
		m = re_sup.search(s)
	# \sqrt{a} → sqrt(a)
	var re_sqrt := RegEx.new()
	re_sqrt.compile("\\\\sqrt\\{([^{}]*)\\}")
	m = re_sqrt.search(s)
	while m != null:
		s = s.substr(0, m.get_start()) + "sqrt(%s)" % m.get_string(1) + s.substr(m.get_end())
		m = re_sqrt.search(s)
	# \frac{a}{b} → ((a)/(b))
	var re_frac := RegEx.new()
	re_frac.compile("\\\\frac\\{([^{}]*)\\}\\{([^{}]*)\\}")
	m = re_frac.search(s)
	while m != null:
		s = s.substr(0, m.get_start()) + "((%s)/(%s))" % [m.get_string(1), m.get_string(2)] \
			+ s.substr(m.get_end())
		m = re_frac.search(s)
	# spacing / delimiters that REDUCE doesn't want
	for junk in ["\\left", "\\right", "\\,", "\\;", "\\!", "\\quad", "\\qquad", "\\displaystyle"]:
		s = s.replace(junk, "")
	# operators / constants
	s = s.replace("\\cdot", "*").replace("\\times", "*")
	s = s.replace("\\infty", "infinity")
	s = s.replace("e^", "exp")   # e^(...) → exp(...) after ^{} expansion
	s = s.replace("expp(", "exp(")
	# remaining \name → name (functions \sin,\cos,… and greek \lambda,\alpha,…)
	var re_cmd := RegEx.new()
	re_cmd.compile("\\\\([A-Za-z]+)")
	m = re_cmd.search(s)
	while m != null:
		s = s.substr(0, m.get_start()) + m.get_string(1) + s.substr(m.get_end())
		m = re_cmd.search(s)
	# Conservative implicit multiplication: ")(" → ")*(", ") x" → ")*x",
	# "2x"/"2(" → "2*x"/"2*(". Only `)` or a digit triggers it, so function
	# calls like sin( are never split.
	s = _insert_implicit_mult(s)
	return s.strip_edges()


func _insert_implicit_mult(s: String) -> String:
	var out := ""
	for i in range(s.length()):
		var ch := s[i]
		if i > 0:
			var p := s[i - 1]
			var p_close := (p == ")")
			var p_digit := (p >= "0" and p <= "9")
			var ch_open := (ch == "(")
			var ch_alpha := (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")
			if (p_close or p_digit) and (ch_open or ch_alpha):
				out += "*"
		out += ch
	return out


## Task 126 (req #9) — build a REAL inline 3D surface plot for a cas-plot3d body
## of the form `z = f(x, y)` (or just `f(x, y)`). Samples with Godot's Expression
## evaluator (no engine round-trip), builds an ArrayMesh coloured by height, and
## returns a SubViewportContainer holding a Camera3D-lit 3D scene — finally using
## Godot's native 3D, which was the whole point of req #9.
func _build_surface3d(expr_src: String) -> Control:
	var e := expr_src.strip_edges()
	var eq := e.find("=")
	if eq != -1 and e.substr(0, eq).strip_edges().to_lower() == "z":
		e = e.substr(eq + 1).strip_edges()
	e = _pow_to_func(e)
	var expr := Expression.new()
	var err := expr.parse(e, ["x", "y"])
	if err != OK:
		var lbl := Label.new()
		lbl.text = "3D plot — cannot parse z = %s  (%s)" % [e, expr.get_error_text()]
		lbl.add_theme_color_override("font_color", _color_scheme["text"])
		return lbl
	# Sample a grid over x, y ∈ [-π, π].
	var N := 56   # task 136/139 — finer mesh → smoother, higher-detail surface
	var lo := -PI
	var hi := PI
	var stp := (hi - lo) / float(N)
	var h := []
	var zmin := INF
	var zmax := -INF
	for i in range(N + 1):
		var row := []
		for j in range(N + 1):
			var z = expr.execute([lo + i * stp, lo + j * stp])
			if not (z is float or z is int):
				z = 0.0
			z = float(z)
			if is_nan(z) or is_inf(z):
				z = 0.0
			row.append(z)
			zmin = minf(zmin, z)
			zmax = maxf(zmax, z)
		h.append(row)
	var zr := maxf(0.001, zmax - zmin)
	var posf := func(i: int, j: int) -> Vector3:
		return Vector3((float(i) / N - 0.5) * 4.0,
			(float(h[i][j]) - zmin) / zr * 2.0 - 1.0,
			(float(j) / N - 0.5) * 4.0)
	var colf := func(i: int, j: int) -> Color:
		# Task 148.5 (req A2) — a perceptually-uniform Viridis ramp (dark valley →
		# bright peak) instead of the old HSV; reads truer and is colour-blind-safe.
		return _viridis((float(h[i][j]) - zmin) / zr)
	var stool := SurfaceTool.new()
	stool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(N):
		for j in range(N):
			var v00: Vector3 = posf.call(i, j)
			var v10: Vector3 = posf.call(i + 1, j)
			var v11: Vector3 = posf.call(i + 1, j + 1)
			var v01: Vector3 = posf.call(i, j + 1)
			for tri in [[v00, i, j, v10, i + 1, j, v11, i + 1, j + 1],
						[v00, i, j, v11, i + 1, j + 1, v01, i, j + 1]]:
				stool.set_color(colf.call(tri[1], tri[2])); stool.add_vertex(tri[0])
				stool.set_color(colf.call(tri[4], tri[5])); stool.add_vertex(tri[3])
				stool.set_color(colf.call(tri[7], tri[8])); stool.add_vertex(tri[6])
	stool.generate_normals()
	stool.set_material(_contour_material())   # task 143/148.6 — PBR + iso-height contours
	var mi := MeshInstance3D.new()
	mi.mesh = stool.commit()
	return _plot3d_scene(mi, lo, hi, lo, hi, zmin, zmax)


## Task 143/148.6 — the PBR + anti-aliased iso-height-contour spatial shader,
## shared by every 3D surface kind. One fragment shader → no extra render pass.
func _contour_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\n" \
		+ "render_mode cull_disabled;\n" \
		+ "uniform float bands = 9.0;\n" \
		+ "uniform vec3 line_color : source_color = vec3(0.04, 0.04, 0.06);\n" \
		+ "varying float v_h;\n" \
		+ "void vertex() { v_h = VERTEX.y; }\n" \
		+ "void fragment() {\n" \
		+ "	ALBEDO = COLOR.rgb;\n" \
		+ "	ROUGHNESS = 0.42; METALLIC = 0.12; RIM = 0.35; RIM_TINT = 0.2;\n" \
		+ "	float s = v_h * bands;\n" \
		+ "	float d = min(fract(s), 1.0 - fract(s));\n" \
		+ "	float w = fwidth(s) * 1.3 + 0.012;\n" \
		+ "	float line = smoothstep(0.0, w, d);\n" \
		+ "	ALBEDO = mix(line_color, ALBEDO, line);\n" \
		+ "}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat


## Task 148.6 — a parametric (u,v) surface: x=f(u,v); y=g(u,v); z=h(u,v) over
## u,v ∈ [0, 2π]. Pure Godot (Expression sampling + SurfaceTool) — tori, spheres,
## shells, Klein-bottle-ish shapes. Normalised to fit the standard plot box.
func _build_parametric3d(body: String) -> Control:
	var src := {"x": "", "y": "", "z": ""}
	for raw in body.replace(";", "\n").split("\n"):
		var line := raw.strip_edges()
		var eq := line.find("=")
		if eq <= 0:
			continue
		var lhs := line.substr(0, eq).strip_edges().to_lower()
		if src.has(lhs):
			src[lhs] = _pow_to_func(line.substr(eq + 1).strip_edges())
	var fx := Expression.new()
	var fy := Expression.new()
	var fz := Expression.new()
	if src["x"] == "" or src["y"] == "" or src["z"] == "" \
			or fx.parse(src["x"], ["u", "v"]) != OK \
			or fy.parse(src["y"], ["u", "v"]) != OK \
			or fz.parse(src["z"], ["u", "v"]) != OK:
		var lbl := Label.new()
		lbl.text = "parametric surface — give  x = …; y = …; z = …  in u, v"
		lbl.add_theme_color_override("font_color", _color_scheme["text"])
		return lbl
	var Nu := 50
	var Nv := 50
	var pts := []
	var bmin := Vector3(INF, INF, INF)
	var bmax := Vector3(-INF, -INF, -INF)
	for iu in range(Nu + 1):
		var row := []
		var uu := lerpf(0.0, TAU, float(iu) / Nu)
		for iv in range(Nv + 1):
			var vv := lerpf(0.0, TAU, float(iv) / Nv)
			var p := Vector3(_eval2(fx, uu, vv), _eval2(fy, uu, vv), _eval2(fz, uu, vv))
			row.append(p)
			bmin = Vector3(minf(bmin.x, p.x), minf(bmin.y, p.y), minf(bmin.z, p.z))
			bmax = Vector3(maxf(bmax.x, p.x), maxf(bmax.y, p.y), maxf(bmax.z, p.z))
		pts.append(row)
	var center := (bmin + bmax) * 0.5
	var ext := maxf(maxf(bmax.x - bmin.x, bmax.y - bmin.y), bmax.z - bmin.z)
	var scl := 3.6 / maxf(0.001, ext)
	var zmin := bmin.z
	var zr := maxf(0.001, bmax.z - bmin.z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iu in range(Nu):
		for iv in range(Nv):
			var quad := [pts[iu][iv], pts[iu + 1][iv], pts[iu + 1][iv + 1], pts[iu][iv + 1]]
			for tri in [[quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]]:
				for vert in tri:
					var p: Vector3 = vert
					st.set_color(_viridis((p.z - zmin) / zr))
					st.add_vertex((p - center) * scl)
	st.generate_normals()
	st.set_material(_contour_material())
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	return _plot3d_scene(mi, bmin.x, bmax.x, bmin.y, bmax.y, bmin.z, bmax.z)


func _eval2(e: Expression, u: float, v: float) -> float:
	var r = e.execute([u, v])
	if not (r is float or r is int):
		return 0.0
	var f := float(r)
	return 0.0 if (is_nan(f) or is_inf(f)) else f


## Task 148.6 — the shared 3D plot scene (viewport, camera, lights, environment,
## axes, colour-bar, drag-rotate + zoom controls) wrapped around a given mesh, so
## height-field, parametric (cas-surface) and other 3D plot kinds reuse one
## renderer (the pluggable-mesh-source architecture from the task-148 plan).
func _plot3d_scene(mi: MeshInstance3D, xlo: float, xhi: float, ylo: float, yhi: float, zmin: float, zmax: float) -> Control:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # fills the stack
	# Task 137 — IGNORE so the scroll wheel reaches the page; task 142 — a PASS
	# drag-overlay above handles left-drag rotation while the wheel still passes.
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.size = Vector2i(1120, 560)                      # task 136 — higher resolution
	vp.msaa_3d = Viewport.MSAA_8X                      # task 136 — smoother edges
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA # task 139 — extra edge AA
	container.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	world.add_child(mi)
	var cam := Camera3D.new()
	cam.position = Vector3(4.0, 3.5, 4.0)              # task 136 — closer → surface fills more
	cam.look_at_from_position(cam.position, Vector3(0, 0, 0), Vector3.UP)
	world.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -40, 0)
	key.light_energy = 1.15
	key.shadow_enabled = true                          # task 139 — self-shadowing depth
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, 135, 0)
	fill.light_energy = 0.4
	world.add_child(fill)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10)     # task 140 — dark plot background
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC  # task 139 — filmic + SSAO + bloom
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 0.7
	env.ssao_intensity = 2.2
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	_add_axes_3d(world, xlo, xhi, ylo, yhi, zmin, zmax)  # task 148.5 — box + tick numbers
	_add_colorbar_3d(world, zmin, zmax)               # task 148.6 — Viridis colour-bar
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 560)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE   # task 137 — wheel falls through
	stack.add_child(container)
	var drag := Control.new()
	drag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag.mouse_filter = Control.MOUSE_FILTER_PASS
	drag.mouse_default_cursor_shape = Control.CURSOR_MOVE
	var dragging := [false]
	drag.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			dragging[0] = ev.pressed
		elif ev is InputEventMouseMotion and dragging[0]:
			mi.global_rotate(Vector3.UP, deg_to_rad(-ev.relative.x * 0.4))
			mi.global_rotate(Vector3.RIGHT, deg_to_rad(-ev.relative.y * 0.4)))
	stack.add_child(drag)
	var wrap := VBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(_make_zoom_bar(
		func(): cam.position *= 1.18; cam.look_at(Vector3.ZERO, Vector3.UP),   # zoom out
		func(): cam.position *= 0.85; cam.look_at(Vector3.ZERO, Vector3.UP),   # zoom in
		func(): mi.rotation = Vector3.ZERO; cam.position = Vector3(4.0, 3.5, 4.0); cam.look_at(Vector3.ZERO, Vector3.UP)))
	wrap.add_child(stack)
	return wrap


## Task 148.6 — a vertical Viridis colour-bar to the right of the surface, with
## the value range labelled, so the height colour-map is quantitative.
func _add_colorbar_3d(world: Node3D, zmin: float, zmax: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 20
	for k in segs:
		var t0 := float(k) / segs
		var t1 := float(k + 1) / segs
		var y0 := -1.0 + t0 * 2.0
		var y1 := -1.0 + t1 * 2.0
		var c0 := _viridis(t0)
		var c1 := _viridis(t1)
		st.set_color(c0); st.add_vertex(Vector3(2.7, y0, 2))
		st.set_color(c0); st.add_vertex(Vector3(2.95, y0, 2))
		st.set_color(c1); st.add_vertex(Vector3(2.95, y1, 2))
		st.set_color(c0); st.add_vertex(Vector3(2.7, y0, 2))
		st.set_color(c1); st.add_vertex(Vector3(2.95, y1, 2))
		st.set_color(c1); st.add_vertex(Vector3(2.7, y1, 2))
	var cmat := StandardMaterial3D.new()
	cmat.vertex_color_use_as_albedo = true
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(cmat)
	var bar := MeshInstance3D.new()
	bar.mesh = st.commit()
	world.add_child(bar)
	_axis_label(world, Vector3(3.35, 1.0, 2), String.num(zmax, 2))
	_axis_label(world, Vector3(3.35, -1.0, 2), String.num(zmin, 2))


## Task 148.5 (req A2) — perceptually-uniform Viridis colour-map (5-stop lerp).
## Dark purple (low) → blue → teal → green → yellow (high); colour-blind-safe.
func _viridis(t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	var stops := [
		Color(0.267, 0.005, 0.329), Color(0.231, 0.318, 0.545),
		Color(0.128, 0.567, 0.551), Color(0.369, 0.789, 0.383),
		Color(0.993, 0.906, 0.144)]
	var seg := t * 4.0
	var i := int(floor(seg))
	if i >= 4:
		return stops[4]
	return (stops[i] as Color).lerp(stops[i + 1] as Color, seg - float(i))


## Task 148.5 (req A1) — a bounding box + axis tick numbers around the 3D surface
## so it reads as a measured plot. The surface spans world x,z ∈ [-2,2], y ∈
## [-1,1]; the labels map those back to the domain (lo..hi) and height (zmin..zmax).
func _add_axes_3d(world: Node3D, xlo: float, xhi: float, ylo: float, yhi: float, zmin: float, zmax: float) -> void:
	var im := ImmediateMesh.new()
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.albedo_color = Color(0.55, 0.60, 0.68)
	im.surface_begin(Mesh.PRIMITIVE_LINES, lmat)
	var c := [
		Vector3(-2, -1, -2), Vector3(2, -1, -2), Vector3(2, -1, 2), Vector3(-2, -1, 2),
		Vector3(-2, 1, -2), Vector3(2, 1, -2), Vector3(2, 1, 2), Vector3(-2, 1, 2)]
	for e in [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]:
		im.surface_add_vertex(c[e[0]])
		im.surface_add_vertex(c[e[1]])
	im.surface_end()
	var box := MeshInstance3D.new()
	box.mesh = im
	world.add_child(box)
	for k in 3:
		var f := float(k) / 2.0
		_axis_label(world, Vector3(-2 + f * 4, -1.18, 2.2), String.num(lerpf(xlo, xhi, f), 2))   # x
		_axis_label(world, Vector3(2.25, -1.18, 2 - f * 4), String.num(lerpf(ylo, yhi, f), 2))   # y
		_axis_label(world, Vector3(-2.35, -1 + f * 2, 2.0), String.num(lerpf(zmin, zmax, f), 2)) # z


func _axis_label(world: Node3D, pos: Vector3, txt: String) -> void:
	var l := Label3D.new()
	l.text = txt
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.82, 0.86, 0.92)
	l.font_size = 44
	l.pixel_size = 0.0042
	l.position = pos
	world.add_child(l)


## Task 136 — a small "zoom −/+/⟳" control bar shared by the 2D and 3D plot cells.
func _make_zoom_bar(on_out: Callable, on_in: Callable, on_reset: Callable) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.text = "zoom"
	lbl.add_theme_font_size_override("font_size", int(_density["chip_size"]))
	lbl.add_theme_color_override("font_color", _color_scheme["muted"])
	bar.add_child(lbl)
	bar.add_child(_zoom_btn("−", on_out))
	bar.add_child(_zoom_btn("+", on_in))
	bar.add_child(_zoom_btn("⟳", on_reset))
	return bar


func _zoom_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(44, 34)
	b.pressed.connect(cb)
	return b


## Task 126 — convert `a^b` to `pow(a, b)` so Godot's Expression (no `^` operator)
## can evaluate a REDUCE-style power. Handles identifiers, numbers, function
## calls, and one level of parentheses on each side.
func _pow_to_func(s: String) -> String:
	var re := RegEx.new()
	re.compile("([A-Za-z_][A-Za-z0-9_]*\\([^()]*\\)|[A-Za-z0-9_.]+|\\([^()]*\\))\\^([A-Za-z0-9_.]+|\\([^()]*\\))")
	var out := s
	var m := re.search(out)
	var guard := 0
	while m != null and guard < 60:
		guard += 1
		out = out.substr(0, m.get_start()) \
			+ "pow(%s,%s)" % [m.get_string(1), m.get_string(2)] + out.substr(m.get_end())
		m = re.search(out)
	return out


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
	_popup.add_item("Clear all outputs", _ID_CLEAR)
	_popup.add_item("Search workspace…  Ctrl+Shift+F", _ID_SEARCH)
	_popup.add_item("Export HTML", _ID_EXPORT)
	_popup.add_separator()
	_popup.add_check_item("Distraction-free", _ID_ZEN)
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
	elif id == _ID_CLEAR:
		_on_clear_outputs()
	elif id == _ID_SEARCH:
		_on_search_workspace()
	elif id == _ID_ZEN:
		_toggle_distraction_free()
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
	_font_resource = _resolve_bold_font(_font_family)
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


## Task 118 — resolve a font family and make it BOLD (bolder text throughout the
## app, except buttons which keep the theme's normal weight). Used everywhere the
## notebook applies its font to cells / editor / tree / labels.
func _resolve_bold_font(family: String) -> Font:
	var f := FontConfig.font_resource(family)
	if f is SystemFont:
		(f as SystemFont).font_weight = 700
	return f


func _on_font_family_changed(idx: int) -> void:
	if idx < 0 or idx >= FontConfig.FAMILIES.size():
		return
	_font_family = FontConfig.FAMILIES[idx]["key"]
	_font_resource = _resolve_bold_font(_font_family)
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
	# Task 115 — tell the top-bar toggle button (main.gd) to update its label.
	view_mode_changed.emit(_is_notebook_view)
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
	# Task 138 — extra scroll room at the bottom so the last cell (e.g. a tall
	# 3D plot) can be scrolled fully into view instead of bumping the bottom edge.
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 480)
	_rendered_box.add_child(tail)


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
	# Task 126 — wikilinks: [[Note]] → a clickable link that opens Note.md.
	var rendered := _linkify_wikilinks("\n".join(converted))
	lbl.text = rendered
	lbl.add_theme_color_override("default_color", _color_scheme["text"])
	if rendered.find("[url=") != -1:
		lbl.meta_clicked.connect(_on_prose_meta_clicked)
	_font_apply(lbl)
	_attach_edit_on_dblclick(lbl)   # task 110 — double-click prose to edit
	_rendered_box.add_child(lbl)


## Task 126 — turn [[Note]] into a coloured, clickable BBCode link.
func _linkify_wikilinks(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\[\\[([^\\]]+)\\]\\]")
	var out := text
	var m := re.search(out)
	while m != null:
		var name := m.get_string(1)
		var link := "[url=%s][color=#0072BD]%s[/color][/url]" % [name, name]
		out = out.substr(0, m.get_start()) + link + out.substr(m.get_end())
		m = re.search(out, m.get_start() + link.length())
	return out


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
	_attach_cell_context_menu(src_panel, block["body"].strip_edges(), block["kind"], int(block["start"]))
	_attach_edit_on_dblclick(src_panel, int(block["start"]))   # task 110/111 — dblclick → edit this cell
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
	# Task 110 — let the double-click reach the panel's edit handler.
	src_text.mouse_filter = Control.MOUSE_FILTER_PASS
	src_text.text = block["body"].strip_edges()
	src_text.add_theme_color_override("default_color", _color_scheme["text"])
	_font_apply(src_text)
	src_v.add_child(src_text)
	_rendered_box.add_child(src_panel)

	# Task 99 — plot rendered INLINE as a framed result cell directly beneath
	# the cas-plot source block, styled + coloured to match the notebook theme.
	if block["kind"] == NotebookRunner.KIND_PLOT \
			and _plot_samples_by_line.has(NotebookRunner.source_hash(block["body"], block["kind"])):
		var ys: PackedFloat64Array = _plot_samples_by_line[NotebookRunner.source_hash(block["body"], block["kind"])]
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
		plot_panel.custom_minimum_size = Vector2(0, 440)   # task 136 — bigger 2D plot
		plot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plot_panel.clip_contents = true                    # task 136 — clip zoom overflow
		if plot_panel.has_method("set_theme_colors"):
			plot_panel.set_theme_colors(
				_color_scheme["src_bg"],                                   # plot bg
				_color_scheme["muted"],                                    # axes
				_color_scheme["muted"].lerp(_color_scheme["src_bg"], 0.6), # grid
				_color_scheme["src_border"])                               # curve
		# Task 136 — zoom controls for the 2D plot.
		pv.add_child(_make_zoom_bar(plot_panel.zoom_out, plot_panel.zoom_in, plot_panel.zoom_reset))
		pv.add_child(plot_panel)
		if plot_panel.has_method("set_samples"):
			plot_panel.set_samples(X_MIN, X_MAX, ys)
		_rendered_box.add_child(plot_cell)
		return

	# Task 126 (req #9) — real inline 3D surface for cas-plot3d blocks.
	if block["kind"] == NotebookRunner.KIND_PLOT3D:
		var cell3d := PanelContainer.new()
		cell3d.add_theme_stylebox_override("panel",
			_make_cell_box(_color_scheme["res_bg"], _color_scheme["res_border"]))
		var v3 := VBoxContainer.new()
		v3.add_theme_constant_override("separation", int(_density["chip_offset"]))
		cell3d.add_child(v3)
		var chip3 := Label.new()
		chip3.text = "= 3D surface   %s" % block["body"].strip_edges()
		chip3.add_theme_color_override("font_color", _color_scheme["res_chip"])
		chip3.add_theme_font_size_override("font_size", int(_density["chip_size"]))
		v3.add_child(chip3)
		v3.add_child(_build_surface3d(block["body"]))
		_rendered_box.add_child(cell3d)
		return

	# Task 148.6 — parametric (u,v) surface for cas-surface blocks.
	if block["kind"] == NotebookRunner.KIND_SURFACE:
		var cellp := PanelContainer.new()
		cellp.add_theme_stylebox_override("panel",
			_make_cell_box(_color_scheme["res_bg"], _color_scheme["res_border"]))
		var vp3 := VBoxContainer.new()
		vp3.add_theme_constant_override("separation", int(_density["chip_offset"]))
		cellp.add_child(vp3)
		var chipp := Label.new()
		chipp.text = "= parametric surface   %s" % block["body"].strip_edges().replace("\n", "  ")
		chipp.add_theme_color_override("font_color", _color_scheme["res_chip"])
		chipp.add_theme_font_size_override("font_size", int(_density["chip_size"]))
		vp3.add_child(chipp)
		vp3.add_child(_build_parametric3d(block["body"]))
		_rendered_box.add_child(cellp)
		return

	if paired_result == null:
		return
	var res_panel := PanelContainer.new()
	res_panel.add_theme_stylebox_override("panel",
		_make_cell_box(_color_scheme["res_bg"], _color_scheme["res_border"]))
	_attach_hover(res_panel, _color_scheme["res_bg"], _color_scheme["res_border"])
	_attach_cell_context_menu(res_panel,
		NotebookRunner.payload_only(paired_result["body"]), "cas-result", int(block["start"]))
	_attach_edit_on_dblclick(res_panel, int(block["start"]))   # task 110/111 — dblclick → edit this cell
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
	res_text.mouse_filter = Control.MOUSE_FILTER_PASS   # task 110 — dblclick to edit
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
## Task 111 — plus "Edit this cell" (jump to its source line in the editor).
func _attach_cell_context_menu(panel: PanelContainer, body: String, kind: String, line: int = -1) -> void:
	panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT \
				and ev.pressed:
			var menu := PopupMenu.new()
			menu.add_item("Edit this cell", 10)
			menu.add_item("Copy source", 0)
			menu.add_separator()
			if kind != "cas-result" and kind != "cas-test-result" \
					and kind != "cas-derive-result" and kind != "cas-plot-result":
				menu.add_item("Re-run this block (Force re-run all)", 2)
			add_child(menu)
			menu.id_pressed.connect(func(id):
				if id == 10:
					_edit_at_line(line)
				elif id == 0:
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
## Task 110 — double-clicking anywhere in the rendered notebook jumps into the
## editable Source view, so editing feels natural (no need to find a toggle).
## Task 111 — and lands the caret on the clicked cell's source line, so it's
## edit-*this*-cell, not just "switch to source".
func _attach_edit_on_dblclick(ctrl: Control, line: int = -1) -> void:
	ctrl.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.double_click \
				and ev.button_index == MOUSE_BUTTON_LEFT and _is_notebook_view:
			_edit_at_line(line))


## Task 111 — switch to the editable Source view and place the caret on `line`
## (the source line of the cell the user acted on). Used by double-click and the
## cell context menu's "Edit this cell".
func _edit_at_line(line: int) -> void:
	if _is_notebook_view:
		_toggle_view_mode()    # → editable Source view
	if _editor == null:
		return
	if line >= 0 and line < _editor.get_line_count():
		_editor.set_caret_line(line)
		_editor.set_caret_column(0)
		_editor.center_viewport_to_caret()
	_editor.grab_focus()


func _make_title_bar(text: String) -> Array:
	var bar := PanelContainer.new()
	# Task 110 — a row, so callers can add controls (e.g. the editor's Edit/View
	# toggle button) to the right of the title label.
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bar.add_child(hb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)   # task 96 — doubled
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	return [bar, lbl, hb]


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
		# Task 107 — the default hover highlight is a dark box that hid the
		# (dark) filename text on the light scheme. Use a faint, scheme-tinted
		# hover box and keep the text colour readable on hover.
		var hov := StyleBoxFlat.new()
		hov.bg_color = _color_scheme["src_border"].lerp(_color_scheme["bg"], 0.82)
		_sidebar_tree.add_theme_stylebox_override("hovered", hov)
		_sidebar_tree.add_theme_stylebox_override("hovered_dimmed", hov)
		_sidebar_tree.add_theme_color_override("font_color", _color_scheme["text"])
		_sidebar_tree.add_theme_color_override("font_selected_color", _color_scheme["text"])
		_sidebar_tree.add_theme_color_override("font_hovered_color", _color_scheme["text"])
		_sidebar_tree.add_theme_color_override("font_hovered_dimmed_color", _color_scheme["text"])
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
