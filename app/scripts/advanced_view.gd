class_name AdvancedView
extends Control
## Advanced-problems browser. Redesigned in task 27 from the original (task 26)
## TabContainer-of-stacked-buttons into a two-pane layout:
##   [ sidebar: ItemList of categories ]  [ search box + 3-col GridContainer ]
##                                         [ bottom: result panel              ]
##
## The category sidebar shows item counts; selecting one repopulates the grid.
## The search field filters within the currently-selected category.
## A run produces a result in the bottom panel without leaving the view.

const COL_BG := Color(0.08, 0.09, 0.11)
const COL_PANEL := Color(0.13, 0.14, 0.17)
const COL_TEXT := Color(0.90, 0.92, 0.95)
const COL_ACCENT := Color(0.20, 0.55, 0.95)
const RADIUS := 10
const PAD := 12
const GRID_COLUMNS := 3
const BTN_HEIGHT := 36

var _categories: Array = []
var _selected_cat_idx := -1
var _filter_text := ""

var _sidebar: ItemList
var _search: LineEdit
var _grid: GridContainer
var _grid_scroll: ScrollContainer
var _category_title: Label
var _category_counter: Label
var _result_input: Label
var _result_output: RichTextLabel
var _result_status: Label
var _pending_id: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_categories = AdvancedLibrary.build()
	_build_ui()
	MathEngine.result_ready.connect(_on_result)
	# Show the first category by default.
	if _categories.size() > 0:
		_sidebar.select(0)
		_select_category(0)


func open_view() -> void:
	visible = true
	move_to_front()


func close_view() -> void:
	visible = false


# ----------------------------------------------------------------------------
# UI construction
# ----------------------------------------------------------------------------
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, PAD)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", PAD)
	margin.add_child(root)

	# --- Header ---
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Advanced Problems"
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)
	var total := 0
	for c in _categories:
		total += int(c["items"].size())
	var counter := Label.new()
	counter.text = "  (%d problems · %d categories)" % [total, _categories.size()]
	counter.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	header.add_child(counter)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "Close   (Esc)"
	close_btn.pressed.connect(close_view)
	header.add_child(close_btn)

	# --- Body split: sidebar | main column ---
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 240
	root.add_child(split)

	# Sidebar
	_sidebar = ItemList.new()
	_sidebar.custom_minimum_size = Vector2(220, 0)
	_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar.add_theme_font_size_override("font_size", 16)
	for cat in _categories:
		_sidebar.add_item("%s   (%d)" % [cat["name"], int(cat["items"].size())])
	_sidebar.item_selected.connect(_select_category)
	split.add_child(_sidebar)

	# Main column: search row + category title + scroll grid
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 8)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(main)

	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)
	main.add_child(search_row)
	_category_title = Label.new()
	_category_title.add_theme_font_size_override("font_size", 20)
	search_row.add_child(_category_title)
	_category_counter = Label.new()
	_category_counter.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	search_row.add_child(_category_counter)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(sp)
	_search = LineEdit.new()
	_search.placeholder_text = "filter…"
	_search.custom_minimum_size = Vector2(280, 0)
	_search.text_changed.connect(_on_search_changed)
	search_row.add_child(_search)
	var clear_btn := Button.new()
	clear_btn.text = "✕"
	clear_btn.tooltip_text = "Clear filter"
	clear_btn.pressed.connect(_clear_filter)
	search_row.add_child(clear_btn)

	_grid_scroll = ScrollContainer.new()
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_scroll.custom_minimum_size = Vector2(0, 280)
	main.add_child(_grid_scroll)
	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_scroll.add_child(_grid)

	# --- Result panel ---
	var result_panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_corner_radius_all(RADIUS)
	sb.set_content_margin_all(12)
	result_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(result_panel)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	result_panel.add_child(rv)
	_result_status = Label.new()
	_result_status.text = "Pick a problem to run it."
	_result_status.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	rv.add_child(_result_status)
	_result_input = Label.new()
	_result_input.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	rv.add_child(_result_input)
	_result_output = RichTextLabel.new()
	_result_output.bbcode_enabled = false
	_result_output.fit_content = true
	_result_output.scroll_active = false
	_result_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_output.add_theme_font_size_override("normal_font_size", 18)
	rv.add_child(_result_output)


# ----------------------------------------------------------------------------
# Category + filter
# ----------------------------------------------------------------------------
func _select_category(idx: int) -> void:
	_selected_cat_idx = idx
	_filter_text = ""
	_search.text = ""
	_repopulate_grid()


func _on_search_changed(text: String) -> void:
	_filter_text = text.strip_edges().to_lower()
	_repopulate_grid()


func _clear_filter() -> void:
	_search.text = ""
	_filter_text = ""
	_repopulate_grid()


func _repopulate_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	if _selected_cat_idx < 0 or _selected_cat_idx >= _categories.size():
		return
	var cat: Dictionary = _categories[_selected_cat_idx]
	var items: Array = cat["items"]
	var shown := 0
	for it in items:
		var label: String = it["label"]
		if _filter_text != "" and not label.to_lower().contains(_filter_text):
			continue
		var btn := Button.new()
		btn.text = label
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, BTN_HEIGHT)
		var captured: Dictionary = it
		btn.pressed.connect(func(): _run_problem(captured))
		_grid.add_child(btn)
		shown += 1
	_category_title.text = cat["name"]
	if _filter_text == "":
		_category_counter.text = "  · %d items" % shown
	else:
		_category_counter.text = "  · %d of %d items match '%s'" % [
			shown, items.size(), _filter_text]


# ----------------------------------------------------------------------------
# Engine routing
# ----------------------------------------------------------------------------
func _run_problem(item: Dictionary) -> void:
	if not MathEngine.is_ready():
		_result_status.text = "Engine not ready"
		return
	_result_input.text = "▶  " + item["input"]
	_result_output.text = "…"
	_result_status.text = "Evaluating…"
	_pending_id = MathEngine.evaluate(item["cmd"])


func _on_result(id: int, output: String, is_error: bool) -> void:
	if id != _pending_id:
		return
	_pending_id = -1
	if is_error:
		_result_status.text = "✗ engine error"
		_result_output.add_theme_color_override("default_color", Color(0.95, 0.45, 0.45))
		_result_output.text = MathFormatter.clean_error(output)
	else:
		_result_status.text = "✓ done"
		_result_output.add_theme_color_override("default_color", COL_TEXT)
		_result_output.text = MathFormatter.to_display(output)


# ----------------------------------------------------------------------------
# Esc closes the view; / focuses search.
# ----------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				close_view()
				get_viewport().set_input_as_handled()
			KEY_SLASH:
				_search.grab_focus()
				get_viewport().set_input_as_handled()
