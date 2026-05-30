class_name HelpWizard
extends Control
## A modal in-window wizard that walks the user through every operation in the
## app. Each step has a title, body (RichTextLabel BBCode), and an optional
## "Try it" button bound to a Callable that demonstrates the operation live.
##
## Used by:
##   var wiz := HelpWizard.new()
##   add_child(wiz)
##   wiz.set_steps([...])
##   wiz.open()

const PANEL_BG := Color(0.13, 0.14, 0.17)
const PAGE_TXT := Color(0.65, 0.68, 0.74)
const TITLE_FS := 26
const BODY_FS := 18
const RADIUS := 12

var _steps: Array = []
var _current := 0

var _page_label: Label
var _title_label: Label
var _body: RichTextLabel
var _btn_back: Button
var _btn_next: Button
var _btn_try: Button
var _btn_close: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func set_steps(steps: Array) -> void:
	_steps = steps
	_current = 0
	if visible:
		_refresh()


func open() -> void:
	_current = 0
	visible = true
	_refresh()
	move_to_front()
	if _btn_next:
		_btn_next.grab_focus()


func close_panel() -> void:
	visible = false


# ----------------------------------------------------------------------------
# UI construction
# ----------------------------------------------------------------------------
func _build_ui() -> void:
	# Dim backdrop (full rect, blocks clicks behind).
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Centred wizard panel.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 560)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(RADIUS)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	# Header row: "Step N of M" + close (×) button.
	var header := HBoxContainer.new()
	v.add_child(header)
	_page_label = Label.new()
	_page_label.add_theme_color_override("font_color", PAGE_TXT)
	header.add_child(_page_label)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp)
	var x_btn := Button.new()
	x_btn.text = "×"
	x_btn.flat = true
	x_btn.add_theme_font_size_override("font_size", 22)
	x_btn.pressed.connect(close_panel)
	header.add_child(x_btn)

	# Step title.
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", TITLE_FS)
	v.add_child(_title_label)

	# Body (BBCode-enabled, scrollable).
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 320)
	_body.add_theme_font_size_override("normal_font_size", BODY_FS)
	v.add_child(_body)

	# Action row.
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	v.add_child(actions)
	_btn_try = Button.new()
	_btn_try.text = "▶  Try it"
	_btn_try.pressed.connect(_on_try)
	actions.add_child(_btn_try)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	_btn_back = Button.new()
	_btn_back.text = "← Back"
	_btn_back.pressed.connect(_on_back)
	actions.add_child(_btn_back)
	_btn_next = Button.new()
	_btn_next.text = "Next →"
	_btn_next.pressed.connect(_on_next)
	actions.add_child(_btn_next)
	_btn_close = Button.new()
	_btn_close.text = "Close"
	_btn_close.pressed.connect(close_panel)
	actions.add_child(_btn_close)


# ----------------------------------------------------------------------------
# State
# ----------------------------------------------------------------------------
func _refresh() -> void:
	if _steps.is_empty():
		return
	var s: Dictionary = _steps[_current]
	_page_label.text = "Step %d of %d" % [_current + 1, _steps.size()]
	_title_label.text = s.get("title", "")
	_body.text = s.get("body", "")
	_btn_back.disabled = _current == 0
	var is_last := _current == _steps.size() - 1
	_btn_next.text = "Done ✓" if is_last else "Next →"
	var t = s.get("try", null)
	_btn_try.visible = t is Callable and (t as Callable).is_valid()


func _on_next() -> void:
	if _current < _steps.size() - 1:
		_current += 1
		_refresh()
	else:
		close_panel()


func _on_back() -> void:
	if _current > 0:
		_current -= 1
		_refresh()


func _on_try() -> void:
	var s: Dictionary = _steps[_current]
	var t = s.get("try", null)
	if t is Callable and (t as Callable).is_valid():
		(t as Callable).call()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				close_panel()
				get_viewport().set_input_as_handled()
			KEY_RIGHT, KEY_PAGEDOWN:
				_on_next()
				get_viewport().set_input_as_handled()
			KEY_LEFT, KEY_PAGEUP:
				_on_back()
				get_viewport().set_input_as_handled()
