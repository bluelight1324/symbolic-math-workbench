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

# Older "strip below editor" plot from task 35 v1 — kept as a fallback
# render target while in source mode.
var _plot_strip: VBoxContainer
var _plot_caption: Label
var _plot_panel: Control

# Async run state: while running, evaluate blocks one at a time so results
# correlate by FIFO. _pending[id] = {pair, new_kind, on_result: Callable}
var _pending: Dictionary = {}
var _run_queue: Array = []
var _run_results: Dictionary = {}  # block-index -> {new_kind, new_body}
var _run_blocks: Array = []
var _run_active := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
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

	# Task 58 — notebook view is the default; reflect in the toggle label.
	_apply_view_mode()


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
	for spec in [
		["Open workspace…", _on_open_workspace],
		["New note", _on_new_note],
		["Save  (Ctrl+S)", _on_save],
		["Run notebook  (F5)", _on_run],
		["Force re-run  (Ctrl+F5)", _on_force_run],
		["Export HTML", _on_export_html],
	]:
		var b := Button.new()
		b.text = spec[0]
		b.pressed.connect(spec[1])
		topbar.add_child(b)
	# Task 58: notebook view is the primary display; the Source mode is an
	# opt-in toggle. Button label reflects the action that clicking it does.
	_view_mode_btn = Button.new()
	_view_mode_btn.text = "Show Source"
	_view_mode_btn.tooltip_text = "Toggle between Notebook (rendered) and raw Source view"
	_view_mode_btn.pressed.connect(_toggle_view_mode)
	topbar.add_child(_view_mode_btn)

	# Task 58 — font family + size controls (persisted via FontConfig).
	var vsep := VSeparator.new()
	topbar.add_child(vsep)
	var font_label := Label.new()
	font_label.text = "Font:"
	font_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	topbar.add_child(font_label)
	_font_family_btn = OptionButton.new()
	for f in FontConfig.FAMILIES:
		_font_family_btn.add_item(f["label"])
	_font_family_btn.tooltip_text = "Font family — persists across launches"
	_font_family_btn.item_selected.connect(_on_font_family_changed)
	topbar.add_child(_font_family_btn)
	var size_label := Label.new()
	size_label.text = "Size:"
	size_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	topbar.add_child(size_label)
	_font_size_spin = SpinBox.new()
	_font_size_spin.min_value = 10
	_font_size_spin.max_value = 32
	_font_size_spin.step = 1
	_font_size_spin.custom_minimum_size = Vector2(80, 0)
	_font_size_spin.tooltip_text = "Font size in points — persists across launches"
	_font_size_spin.value_changed.connect(_on_font_size_changed)
	topbar.add_child(_font_size_spin)

	# Task 60 — colour scheme dropdown (persisted via ColorConfig).
	topbar.add_child(VSeparator.new())
	var theme_label := Label.new()
	theme_label.text = "Theme:"
	theme_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	topbar.add_child(theme_label)
	_color_btn = OptionButton.new()
	for k in ColorConfig.ordered_keys():
		_color_btn.add_item(ColorConfig.scheme(k)["label"])
	_color_btn.tooltip_text = "Colour scheme — persists across launches"
	_color_btn.item_selected.connect(_on_color_changed)
	topbar.add_child(_color_btn)

	# Task 61 — beautification: density preset + shadow / animation toggles.
	topbar.add_child(VSeparator.new())
	var style_label := Label.new()
	style_label.text = "Style:"
	style_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	topbar.add_child(style_label)
	_density_btn = OptionButton.new()
	for k in StyleConfig.ordered_keys():
		_density_btn.add_item(StyleConfig.density(k)["label"])
	_density_btn.tooltip_text = "Density preset — cell spacing, padding, corner radius"
	_density_btn.item_selected.connect(_on_density_changed)
	topbar.add_child(_density_btn)
	_shadows_check = CheckBox.new()
	_shadows_check.text = "Shadows"
	_shadows_check.tooltip_text = "Subtle drop shadow under each cell"
	_shadows_check.toggled.connect(_on_shadows_toggled)
	topbar.add_child(_shadows_check)
	_anim_check = CheckBox.new()
	_anim_check.text = "Animations"
	_anim_check.tooltip_text = "Fade between Source ↔ Notebook view"
	_anim_check.toggled.connect(_on_animations_toggled)
	topbar.add_child(_anim_check)

	# Split: sidebar | editor.
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 280
	v.add_child(split)

	_sidebar_tree = Tree.new()
	_sidebar_tree.custom_minimum_size = Vector2(240, 0)
	_sidebar_tree.hide_root = false
	_sidebar_tree.allow_reselect = true
	_sidebar_tree.item_activated.connect(_on_tree_item_activated)
	split.add_child(_sidebar_tree)

	# A container that holds both the raw source CodeEdit and the rendered
	# notebook view; only one is visible at a time (task 35 v2).
	_editor_container = Control.new()
	_editor_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_editor_container)

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
	_rendered_box = VBoxContainer.new()
	_rendered_box.add_theme_constant_override("separation", 12)
	_rendered_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rendered_scroll.add_child(_rendered_box)

	# Inline plot strip — appears only when a cas-plot block has just produced
	# samples; hidden by default so the notebook view never has a permanent
	# plot pane (task 35).
	_plot_strip = VBoxContainer.new()
	_plot_strip.visible = false
	_plot_strip.add_theme_constant_override("separation", 4)
	v.add_child(_plot_strip)
	var plot_header := HBoxContainer.new()
	plot_header.add_theme_constant_override("separation", 8)
	_plot_strip.add_child(plot_header)
	_plot_caption = Label.new()
	_plot_caption.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	plot_header.add_child(_plot_caption)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot_header.add_child(sp)
	var hide_btn := Button.new()
	hide_btn.text = "Hide plot"
	hide_btn.pressed.connect(_hide_plot_strip)
	plot_header.add_child(hide_btn)
	_plot_panel = preload("res://scripts/plot_panel.gd").new()
	_plot_panel.custom_minimum_size = Vector2(0, 220)
	_plot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot_strip.add_child(_plot_panel)

	# Status bar at the bottom.
	_status = Label.new()
	_status.text = "Ready"
	v.add_child(_status)

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
	_status.text = "Opened %s" % path
	# A previously-shown plot belongs to the previous file; hide it.
	_hide_plot_strip()
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
		# Task 35: store the samples by block start-line so the rendered
		# (Mathematica-style) view can draw the plot directly beneath the
		# cas-plot block. Also keep the strip-style fallback for source mode.
		var ys := MathFormatter.parse_number_list(output)
		_plot_samples_by_line[int(pair["source"]["start"])] = ys
		_show_plot_strip(pair["source"]["body"].strip_edges(), ys)
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


## Task 35 — inline plot strip control.
const X_MIN := -10.0
const X_MAX := 10.0

func _show_plot_strip(expr: String, ys: PackedFloat64Array) -> void:
	if _plot_strip == null or _plot_panel == null:
		return
	if ys.is_empty():
		return
	_plot_caption.text = "Plot:  %s   (%d samples · x ∈ [%d, %d])" % [
		expr, ys.size(), int(X_MIN), int(X_MAX)]
	if _plot_panel.has_method("set_samples"):
		_plot_panel.set_samples(X_MIN, X_MAX, ys)
	_plot_strip.visible = true


func _hide_plot_strip() -> void:
	if _plot_strip == null:
		return
	_plot_strip.visible = false
	if _plot_panel and _plot_panel.has_method("clear_plot"):
		_plot_panel.clear_plot()


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
	if _is_notebook_view:
		_rebuild_rendered_cells()
		_hide_plot_strip()    # strip is the source-mode preview; not needed here


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
	lbl.add_theme_font_size_override("normal_font_size", 16)
	# Tiny markdown-ish rendering: # / ## headings, otherwise paragraphs.
	var converted := PackedStringArray()
	for line in t.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("## "):
			converted.append("[font_size=22][b]%s[/b][/font_size]" % stripped.substr(3))
		elif stripped.begins_with("# "):
			converted.append("[font_size=26][b]%s[/b][/font_size]" % stripped.substr(2))
		else:
			converted.append(line)
	lbl.text = "\n".join(converted)
	lbl.add_theme_color_override("default_color", _color_scheme["text"])
	_font_apply(lbl)
	_rendered_box.add_child(lbl)


func _emit_block_cell(block: Dictionary, paired_result) -> void:
	# Two stacked PanelContainers: source on top, result/plot below.
	# Tasks 60 + 61: all colours come from the active scheme, all paddings
	# / radii / border widths come from the active density preset.
	var src_panel := PanelContainer.new()
	src_panel.add_theme_stylebox_override("panel",
		_make_cell_box(_color_scheme["src_bg"], _color_scheme["src_border"]))
	var src_v := VBoxContainer.new()
	src_v.add_theme_constant_override("separation", int(_density["chip_offset"]))
	src_panel.add_child(src_v)
	var src_kind_lbl := Label.new()
	src_kind_lbl.text = "▸ " + block["kind"]
	src_kind_lbl.add_theme_color_override("font_color", _color_scheme["src_chip"])
	src_kind_lbl.add_theme_font_size_override("font_size", int(_density["chip_size"]))
	src_v.add_child(src_kind_lbl)
	var src_text := RichTextLabel.new()
	src_text.bbcode_enabled = false
	src_text.fit_content = true
	src_text.scroll_active = false
	src_text.text = block["body"].strip_edges()
	src_text.add_theme_color_override("default_color", _color_scheme["text"])
	_font_apply(src_text)
	src_v.add_child(src_text)
	_rendered_box.add_child(src_panel)

	# Result / plot below the source block.
	if block["kind"] == NotebookRunner.KIND_PLOT \
			and _plot_samples_by_line.has(int(block["start"])):
		var ys: PackedFloat64Array = _plot_samples_by_line[int(block["start"])]
		var plot_panel := preload("res://scripts/plot_panel.gd").new()
		plot_panel.custom_minimum_size = Vector2(0, 220)
		plot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rendered_box.add_child(plot_panel)
		if plot_panel.has_method("set_samples"):
			plot_panel.set_samples(X_MIN, X_MAX, ys)
		return

	if paired_result == null:
		return
	var res_panel := PanelContainer.new()
	res_panel.add_theme_stylebox_override("panel",
		_make_cell_box(_color_scheme["res_bg"], _color_scheme["res_border"]))
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


## One StyleBoxFlat for a cell — colour / padding / corner radius / border
## thickness pull from the active scheme + density. Shadow is conditional on
## the user's checkbox.
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
