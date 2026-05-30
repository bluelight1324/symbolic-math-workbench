class_name IconMenuBar
extends HBoxContainer
## Visual menu bar built from styled `Button` + `StyleBoxFlat` controls instead
## of Godot's plain-text `MenuBar` node. Each category is an icon-glyph button
## with a tinted background, hover/press states, a coloured bottom accent, and
## a tooltip; clicking pops up the category's `PopupMenu` just below the
## button.
##
## (Task 23 — the menu bar "uses Godot" beyond a text-only widget.)

const BTN_SIZE := Vector2(72, 64)
const RADIUS := 10
const FONT_SIZE_ICON := 28
const FONT_SIZE_LABEL := 12

var _menus_by_button: Dictionary = {}      # Button -> PopupMenu


func _ready() -> void:
	add_theme_constant_override("separation", 6)


## Append a category. `icon` is the glyph shown big, `label` is the small text
## under it (and the tooltip), `menu` is the popup that fires on click,
## `accent` tints the bottom border + hover/press fills.
func add_category(icon: String, label: String, menu: PopupMenu, accent: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = BTN_SIZE
	btn.tooltip_text = label
	btn.focus_mode = Control.FOCUS_NONE   # tabbing through menu buttons would be noisy

	# Inner VBox: big icon glyph above, tiny label below.
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE   # let the Button receive clicks
	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", FONT_SIZE_ICON)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(icon_lbl)
	var text_lbl := Label.new()
	text_lbl.text = label
	text_lbl.add_theme_font_size_override("font_size", FONT_SIZE_LABEL)
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(text_lbl)
	btn.add_child(v)

	# StyleBoxes — base / hover / pressed share corner radius and bottom accent.
	var base := _make_box(accent.darkened(0.55), accent)
	var hover := _make_box(accent.darkened(0.30), accent)
	var pressed := _make_box(accent.darkened(0.10), accent)
	btn.add_theme_stylebox_override("normal", base)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	# Plain text colours so the bg StyleBox is the only thing tinting.
	for c in [icon_lbl, text_lbl]:
		c.add_theme_color_override("font_color", Color(0.93, 0.95, 0.97))

	add_child(btn)
	add_child(menu)
	_menus_by_button[btn] = menu
	btn.pressed.connect(func(): _show_menu(btn))
	return btn


func _make_box(bg: Color, accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.border_color = accent
	sb.border_width_bottom = 3
	return sb


func _show_menu(btn: Button) -> void:
	var menu: PopupMenu = _menus_by_button[btn]
	var top_left := btn.get_screen_position() + Vector2(0, btn.size.y)
	menu.popup(Rect2i(int(top_left.x), int(top_left.y), 0, 0))
