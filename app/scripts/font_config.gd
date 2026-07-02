class_name FontConfig
extends RefCounted
## Persistent user-chosen font family + size for the notebook view.
## Lives at user://font.cfg; loaded by notebook_view at startup and
## rewritten whenever the user changes the dropdown / spinbox. (Task 58.)

const PATH := "user://font.cfg"
# Task 96 — default notebook font size doubled at startup (was 18).
const DEFAULT_SIZE := 36
# Task 97 — default to MATLAB's font (Courier New, else Verdana) throughout.
const DEFAULT_FAMILY := "matlab"

# Each entry: a key for persistence + a label for the OptionButton + a list of
# system font names tried in order (first available wins). An empty `names`
# means "use the theme default" — i.e. no override.
const FAMILIES := [
	# Generics
	{"key": "default", "label": "Default",   "names": []},
	{"key": "system",  "label": "System UI", "names": [
		"Segoe UI Variable", "Segoe UI", "SF Pro Text",
		"Helvetica Neue", "Helvetica", "Arial", "sans-serif"]},
	{"key": "sans",    "label": "Sans-Serif", "names": [
		"Segoe UI", "Helvetica Neue", "Helvetica",
		"Arial", "sans-serif"]},
	{"key": "serif",   "label": "Serif", "names": [
		"Cambria", "Georgia", "Times New Roman", "serif"]},
	{"key": "mono",    "label": "Monospace", "names": [
		"JetBrains Mono", "Cascadia Code", "Cascadia Mono",
		"Consolas", "Courier New", "monospace"]},

	# Task 97 — the font MATLAB uses. MATLAB's fixed-width / editor font
	# resolves to "Courier New" on Windows (its "Monospaced" logical font);
	# fall back to Verdana when Courier New is unavailable, as requested.
	{"key": "matlab",  "label": "MATLAB (Courier New)", "names": [
		"Courier New", "Verdana"]},

	# Programming-specific (each surfaced individually for users who care)
	{"key": "fira_code",  "label": "Fira Code", "names": [
		"Fira Code", "Cascadia Code", "Consolas", "monospace"]},
	{"key": "jb_mono",    "label": "JetBrains Mono", "names": [
		"JetBrains Mono", "Cascadia Mono", "Consolas", "monospace"]},
	{"key": "cascadia",   "label": "Cascadia Code", "names": [
		"Cascadia Code", "Cascadia Mono", "Consolas", "monospace"]},
	{"key": "source_code","label": "Source Code Pro", "names": [
		"Source Code Pro", "Consolas", "Courier New", "monospace"]},

	# Modern UI sans-serifs
	{"key": "inter",   "label": "Inter", "names": [
		"Inter", "Inter Display", "Segoe UI", "Helvetica Neue", "sans-serif"]},
	{"key": "roboto",  "label": "Roboto", "names": [
		"Roboto", "Roboto Flex", "Segoe UI", "Helvetica Neue", "sans-serif"]},
	{"key": "open_sans","label": "Open Sans", "names": [
		"Open Sans", "Segoe UI", "Helvetica Neue", "sans-serif"]},
	{"key": "lato",    "label": "Lato", "names": [
		"Lato", "Segoe UI", "Helvetica Neue", "sans-serif"]},

	# Reading / display serifs
	{"key": "charter", "label": "Charter", "names": [
		"Charter", "Cambria", "Georgia", "Times New Roman", "serif"]},
	{"key": "lora",    "label": "Lora", "names": [
		"Lora", "Georgia", "Times New Roman", "serif"]},
	{"key": "merriweather", "label": "Merriweather", "names": [
		"Merriweather", "Georgia", "Times New Roman", "serif"]},

	# Math / academic
	{"key": "cmu_serif",  "label": "CMU / Latin Modern", "names": [
		"Latin Modern Roman", "CMU Serif", "Cambria Math",
		"Cambria", "Times New Roman", "serif"]},

	# Casual / legacy bundled
	{"key": "verdana", "label": "Verdana", "names": ["Verdana", "Tahoma", "sans-serif"]},
	{"key": "tahoma",  "label": "Tahoma",  "names": ["Tahoma", "Verdana", "sans-serif"]},
	{"key": "trebuchet","label": "Trebuchet MS", "names": ["Trebuchet MS", "Tahoma", "sans-serif"]},
	{"key": "calibri", "label": "Calibri", "names": ["Calibri", "Segoe UI", "Helvetica", "sans-serif"]},
	{"key": "comic",   "label": "Comic Sans MS", "names": ["Comic Sans MS", "Comic Sans", "sans-serif"]},

	# Proprietary brand fonts — opportunistic (see task 59 doc).
	{"key": "facebook", "label": "Facebook", "names": [
		"Facebook Sans", "Facebook Letter Faces",
		"Optimistic Display", "Optimistic Text",
		"FB Display", "FB Text",
		"Helvetica Neue", "Helvetica", "Arial", "sans-serif"]},
	{"key": "google",   "label": "Google", "names": [
		"Google Sans", "Google Sans Text", "Product Sans",
		"Roboto", "Helvetica Neue", "sans-serif"]},
	{"key": "apple",    "label": "Apple", "names": [
		"SF Pro Text", "SF Pro Display", "SF Pro",
		"-apple-system", "Helvetica Neue", "Helvetica", "sans-serif"]},
]


static func load_size() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return DEFAULT_SIZE
	return int(cfg.get_value("user", "size", DEFAULT_SIZE))


static func load_family() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return DEFAULT_FAMILY
	return String(cfg.get_value("user", "family", DEFAULT_FAMILY))


static func save_pair(size: int, family: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("user", "size", size)
	cfg.set_value("user", "family", family)
	cfg.save(PATH)


# Task 264/266/268 (MR-F1/F2) — a math-symbol FALLBACK so glyphs the chosen family
# lacks (∫ ∑ ∂ ∇ √ ≤ ≥ ≠ → ℝ ℂ ℤ …) always render instead of tofu (□).
#
# Task 268 — a real math font is now BUNDLED: STIX Two Math (SIL OFL), shipped in
# app/fonts/. It's the PRIMARY fallback, so coverage is guaranteed on ANY machine
# (Linux/mac/Windows without Cambria). Behind it, the system math fonts below remain
# as a further fallback. (JuliaMono was intended too, but its i:\fonts checkout was a
# broken/incomplete git clone with no usable .ttf, so only STIX is bundled.)
const BUNDLED_MATH_FONT := "res://fonts/STIXTwoMath-Regular.otf"
const MATH_FALLBACK_NAMES := [
	# Windows
	"Cambria Math", "Segoe UI Symbol", "Segoe UI Historic",
	# macOS
	"STIX Two Math", "STIXGeneral", "Apple Symbols",
	# Linux / cross-platform (OFL / permissive)
	"Noto Sans Math", "Noto Sans Symbols 2", "DejaVu Sans", "Symbola",
	# generic last resort
	"Segoe UI", "sans-serif"]
static var _math_fallback: Font


## The shared math-symbol fallback: the bundled STIX Two Math (loaded at runtime, so
## no import-cache regen is needed), backed by the system math fonts. Falls back to
## the system-only chain if the bundled file is somehow missing. Built once, cached.
static func math_font() -> Font:
	if _math_fallback == null:
		var sysfb := SystemFont.new()
		sysfb.font_names = PackedStringArray(MATH_FALLBACK_NAMES)
		var ff := FontFile.new()
		if ff.load_dynamic_font(BUNDLED_MATH_FONT) == OK and ff.get_font_name() != "":
			ff.fallbacks = [sysfb]        # bundled STIX → system math fonts
			_math_fallback = ff
		else:
			_math_fallback = sysfb        # bundle missing → system-only
	return _math_fallback


## Returns a SystemFont resource for the requested family key, or null if
## the user picked "default" (in which case caller should not override the
## theme font and the existing default applies). Task 264 — every returned font
## carries the math fallback so math symbols never render as tofu.
static func font_resource(family_key: String) -> Font:
	for f in FAMILIES:
		if f["key"] != family_key:
			continue
		var names: Array = f["names"]
		if names.is_empty():
			return null
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(names)
		sf.fallbacks = [math_font()]
		return sf
	return null


static func family_index(family_key: String) -> int:
	for i in range(FAMILIES.size()):
		if FAMILIES[i]["key"] == family_key:
			return i
	return 0
