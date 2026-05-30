class_name PackageSettings
extends Control
## Modal settings dialog (task 32): tick which optional REDUCE packages are
## loaded at engine startup. The tick state persists via PackageConfig; an
## Apply restarts the engine session so the new package set actually takes
## effect.
##
## Grouped by tier (1 = recommended, 2 = useful, 3 = specialised) so users
## know what to opt into first.

const COL_PANEL := Color(0.13, 0.14, 0.17)
const COL_TEXT := Color(0.93, 0.95, 0.97)
const COL_ACCENT := Color(0.20, 0.55, 0.95)
const RADIUS := 12

signal apply_requested(selected_names: Array)   # main wires this to engine restart

var _checks: Dictionary = {}    # name (String) -> CheckBox
var _initial_selected: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open() -> void:
	_initial_selected = PackageConfig.load_selected()
	for n in _checks.keys():
		(_checks[n] as CheckBox).button_pressed = _initial_selected.has(n)
	visible = true
	move_to_front()


func close_panel() -> void:
	visible = false


# ----------------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------------
func _build_ui() -> void:
	# Dim backdrop.
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Centred panel.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(840, 620)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_corner_radius_all(RADIUS)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = "REDUCE packages — loaded at startup"
	title.add_theme_font_size_override("font_size", 22)
	v.add_child(title)

	var help := Label.new()
	help.text = ("Tick packages to load on every engine start. Changes apply "
		+ "to the current session via a quick engine restart on [Apply].")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(800, 0)
	help.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	v.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	# Group by tier.
	const TIER_TITLES := {
		1: "Recommended — small, broadly useful",
		2: "Useful — modest size, specific domains",
		3: "Specialised — larger / niche",
	}
	for tier in [1, 2, 3]:
		var header := Label.new()
		header.text = "Tier %d   %s" % [tier, TIER_TITLES[tier]]
		header.add_theme_font_size_override("font_size", 16)
		header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.55))
		col.add_child(header)
		for pkg in PackageConfig.KNOWN:
			if pkg["tier"] != tier:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			col.add_child(row)
			var cb := CheckBox.new()
			cb.text = pkg["name"]
			cb.custom_minimum_size = Vector2(160, 0)
			row.add_child(cb)
			_checks[pkg["name"]] = cb
			var desc := Label.new()
			desc.text = pkg["desc"]
			desc.add_theme_color_override("font_color", Color(0.78, 0.82, 0.86))
			row.add_child(desc)

	# Footer buttons.
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	v.add_child(actions)
	var defaults_btn := Button.new()
	defaults_btn.text = "Restore defaults"
	defaults_btn.pressed.connect(_restore_defaults)
	actions.add_child(defaults_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(close_panel)
	actions.add_child(cancel_btn)
	var apply_btn := Button.new()
	apply_btn.text = "Apply  (engine restart)"
	apply_btn.pressed.connect(_apply)
	actions.add_child(apply_btn)


func _restore_defaults() -> void:
	for n in _checks.keys():
		(_checks[n] as CheckBox).button_pressed = \
			PackageConfig.DEFAULT_SELECTED.has(n)


func _apply() -> void:
	var selected: Array = []
	for pkg in PackageConfig.KNOWN:   # KNOWN order is the canonical load order
		var n: String = pkg["name"]
		if (_checks[n] as CheckBox).button_pressed:
			selected.append(n)
	PackageConfig.save_selected(selected)
	apply_requested.emit(selected)
	close_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()
