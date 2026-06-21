class_name StyleConfig
extends RefCounted
## Persisted density / rounding / animation preferences for the notebook
## view (task 61 — "beautify the interface"). Three bundled density
## presets (Compact / Default / Comfortable) plus two booleans
## (shadows, animations).

const PATH := "user://style.cfg"
const DEFAULT_DENSITY := "default"

# Each density preset bundles the visual constants that the cell builders
# and rendered_box use. Picking a density is one click; advanced users can
# still override individual values later if needed.
const DENSITIES := {
	# Task 96 — chip_size doubled so the cell kind/result chips stay legible
	# next to the now-doubled cell body text.
	"compact": {
		"label":          "Compact",
		"cell_separation": 6,    # _rendered_box.add_theme_constant_override("separation", N)
		"cell_padding":    6,    # StyleBoxFlat.content_margin_all on each cell panel
		"corner_radius":   4,    # StyleBoxFlat.set_corner_radius_all
		"border_width":    2,    # StyleBoxFlat.border_width_left
		"chip_size":       24,
		"chip_offset":     1,    # extra v-space between chip label and content
	},
	"default": {
		"label":          "Default",
		"cell_separation": 12,
		"cell_padding":    8,
		"corner_radius":   6,
		"border_width":    3,
		"chip_size":       26,
		"chip_offset":     2,
	},
	"comfortable": {
		"label":          "Comfortable",
		"cell_separation": 20,
		"cell_padding":    14,
		"corner_radius":   10,
		"border_width":    4,
		"chip_size":       28,
		"chip_offset":     4,
	},
}


static func load_density() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return DEFAULT_DENSITY
	var k := String(cfg.get_value("user", "density", DEFAULT_DENSITY))
	return k if DENSITIES.has(k) else DEFAULT_DENSITY


static func load_shadows() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return true
	return bool(cfg.get_value("user", "shadows", true))


static func load_animations() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return true
	return bool(cfg.get_value("user", "animations", true))


static func save(density: String, shadows: bool, animations: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("user", "density", density)
	cfg.set_value("user", "shadows", shadows)
	cfg.set_value("user", "animations", animations)
	cfg.save(PATH)


static func density(key: String) -> Dictionary:
	return DENSITIES.get(key, DENSITIES[DEFAULT_DENSITY])


static func ordered_keys() -> Array:
	return ["compact", "default", "comfortable"]


static func index_of(key: String) -> int:
	var ks := ordered_keys()
	for i in range(ks.size()):
		if ks[i] == key:
			return i
	return 1
