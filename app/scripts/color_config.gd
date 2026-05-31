class_name ColorConfig
extends RefCounted
## Persisted colour-scheme choice for the notebook view (task 60).
## Five bundled palettes; the picked key is saved to user://color.cfg and
## reloaded on the next launch.

const PATH := "user://color.cfg"
const DEFAULT_KEY := "dark"

# Each scheme is a Dictionary with the slots the notebook cell builders need.
# Keys (with which control uses them):
#   bg          — ColorRect background of the notebook view
#   src_bg      — PanelContainer fill of `cas` source cells
#   src_border  — left-accent border of source cells
#   src_chip    — colour of the "▸ cas / cas-test / …" chip label
#   res_bg      — PanelContainer fill of `cas-result` cells
#   res_border  — left-accent border of result cells
#   res_chip    — colour of the "= result" chip label
#   text        — main label / RichTextLabel font_color override
#   muted       — secondary / caption label colour
const SCHEMES := {
	"dark": {
		"label": "Dark",
		"bg":          Color(0.08, 0.09, 0.11),
		"src_bg":      Color(0.10, 0.12, 0.15),
		"src_border":  Color(0.30, 0.35, 0.40),
		"src_chip":    Color(0.55, 0.75, 0.95),
		"res_bg":      Color(0.09, 0.16, 0.10),
		"res_border":  Color(0.30, 0.55, 0.35),
		"res_chip":    Color(0.55, 0.95, 0.65),
		"text":        Color(0.93, 0.95, 0.97),
		"muted":       Color(0.65, 0.70, 0.78),
	},
	"light": {
		"label": "Light",
		"bg":          Color(0.96, 0.97, 0.98),
		"src_bg":      Color(0.91, 0.94, 0.98),
		"src_border":  Color(0.30, 0.50, 0.85),
		"src_chip":    Color(0.20, 0.45, 0.75),
		"res_bg":      Color(0.88, 0.96, 0.90),
		"res_border":  Color(0.25, 0.65, 0.40),
		"res_chip":    Color(0.18, 0.55, 0.30),
		"text":        Color(0.13, 0.17, 0.22),
		"muted":       Color(0.40, 0.45, 0.52),
	},
	"solarized_dark": {
		"label": "Solarized Dark",
		"bg":          Color(0.000, 0.169, 0.212),
		"src_bg":      Color(0.027, 0.212, 0.259),
		"src_border":  Color(0.149, 0.545, 0.824),
		"src_chip":    Color(0.149, 0.545, 0.824),
		"res_bg":      Color(0.027, 0.212, 0.180),
		"res_border":  Color(0.522, 0.600, 0.000),
		"res_chip":    Color(0.522, 0.600, 0.000),
		"text":        Color(0.514, 0.580, 0.588),
		"muted":       Color(0.345, 0.431, 0.459),
	},
	"solarized_light": {
		"label": "Solarized Light",
		"bg":          Color(0.992, 0.965, 0.890),
		"src_bg":      Color(0.933, 0.910, 0.835),
		"src_border":  Color(0.149, 0.545, 0.824),
		"src_chip":    Color(0.149, 0.545, 0.824),
		"res_bg":      Color(0.870, 0.929, 0.835),
		"res_border":  Color(0.522, 0.600, 0.000),
		"res_chip":    Color(0.522, 0.600, 0.000),
		"text":        Color(0.396, 0.482, 0.514),
		"muted":       Color(0.576, 0.631, 0.631),
	},
	# Task 64 §F-38 / task 68 — deuteranopia / protanopia-friendly palette.
	# Blue + orange instead of red + green so the source/result distinction
	# survives common red-green colour-vision deficiencies.
	"colorblind": {
		"label": "Colour-blind safe",
		"bg":          Color(0.09, 0.10, 0.13),
		"src_bg":      Color(0.10, 0.14, 0.22),
		"src_border":  Color(0.27, 0.55, 0.88),   # azure
		"src_chip":    Color(0.50, 0.78, 1.00),
		"res_bg":      Color(0.20, 0.13, 0.06),
		"res_border":  Color(0.95, 0.55, 0.10),   # amber
		"res_chip":    Color(1.00, 0.78, 0.30),
		"text":        Color(0.94, 0.96, 0.98),
		"muted":       Color(0.70, 0.74, 0.80),
	},
	"high_contrast": {
		"label": "High Contrast",
		"bg":          Color.BLACK,
		"src_bg":      Color(0.08, 0.08, 0.08),
		"src_border":  Color.WHITE,
		"src_chip":    Color.WHITE,
		"res_bg":      Color(0.10, 0.10, 0.05),
		"res_border":  Color.YELLOW,
		"res_chip":    Color.YELLOW,
		"text":        Color.WHITE,
		"muted":       Color(0.85, 0.85, 0.85),
	},
}


static func load_key() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return DEFAULT_KEY
	var k := String(cfg.get_value("user", "key", DEFAULT_KEY))
	return k if SCHEMES.has(k) else DEFAULT_KEY


static func save_key(key: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("user", "key", key)
	cfg.save(PATH)


static func scheme(key: String) -> Dictionary:
	return SCHEMES.get(key, SCHEMES[DEFAULT_KEY])


static func ordered_keys() -> Array:
	return ["dark", "light", "solarized_dark", "solarized_light",
		"colorblind", "high_contrast"]


static func index_of(key: String) -> int:
	var ks := ordered_keys()
	for i in range(ks.size()):
		if ks[i] == key:
			return i
	return 0
