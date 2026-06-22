class_name LooksConfig
extends RefCounted
## Task 64 §J / task 68 — bundled "Looks" that combine theme + density +
## font + shadows + animations into one preset. Picking a Look applies
## every constituent setting at once and persists each via its own config.

const LOOKS := {
	"default": {
		"label": "Default",
		"color": "dark",
		"density": "default",
		"font_family": "default",
		"font_size": 18,
		"shadows": true,
		"animations": true,
	},
	"notebook": {
		"label": "Notebook",
		"color": "light",
		"density": "comfortable",
		"font_family": "serif",
		"font_size": 20,
		"shadows": true,
		"animations": true,
	},
	"lab": {
		"label": "Lab",
		"color": "solarized_dark",
		"density": "default",
		"font_family": "mono",
		"font_size": 16,
		"shadows": false,
		"animations": true,
	},
	"lecture": {
		"label": "Lecture",
		"color": "light",
		"density": "comfortable",
		"font_family": "system",
		"font_size": 22,
		"shadows": true,
		"animations": true,
	},
	"mathematica": {
		"label": "Mathematica",
		"color": "light",
		"density": "default",
		"font_family": "cmu_serif",
		"font_size": 18,
		"shadows": true,
		"animations": true,
	},
	# Task 94 — resemble the MATLAB desktop: light MATLAB palette, tight
	# (compact) square-ish panels, a monospace command/editor font, and a flat
	# finish (no drop-shadows, no fade animations) like MATLAB's chrome.
	"matlab": {
		"label": "MATLAB",
		"color": "matlab",
		"density": "compact",
		"font_family": "matlab",
		"font_size": 32,
		"shadows": false,
		"animations": false,
	},
	# Task 129 — the MATLAB desktop in its dark theme.
	"matlab_dark": {
		"label": "MATLAB Dark",
		"color": "matlab_dark",
		"density": "compact",
		"font_family": "matlab",
		"font_size": 32,
		"shadows": false,
		"animations": false,
	},
	"brutalist": {
		"label": "Brutalist",
		"color": "high_contrast",
		"density": "compact",
		"font_family": "sans",
		"font_size": 16,
		"shadows": false,
		"animations": false,
	},
}


static func ordered_keys() -> Array:
	return ["matlab", "matlab_dark", "default", "notebook", "lab", "lecture", "mathematica", "brutalist"]


static func get_look(key: String) -> Dictionary:
	return LOOKS.get(key, LOOKS["default"])


static func index_of(key: String) -> int:
	var ks := ordered_keys()
	for i in range(ks.size()):
		if ks[i] == key:
			return i
	return 0
