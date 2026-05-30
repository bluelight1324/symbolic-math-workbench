class_name PackageConfig
extends RefCounted
## Persistent config of which optional REDUCE packages to load at startup.
## Read by `math_engine.gd` during `_start()`; written by `package_settings.gd`
## when the user ticks/unticks a checkbox and presses Apply.
##
## File: user://packages.cfg
## Format:
##   [defaults]
##   names = ["odesolve", "taylor", "limits"]
##   [user]
##   names = ["odesolve", "taylor", "limits", "defint", "specfn"]
##
## All package names live in `KNOWN`. Loading order is the order in `KNOWN`,
## not the order the user ticked them, so the result is deterministic.

const PATH := "user://packages.cfg"

## Every package the UI offers, with tier and one-line description.
## Tier 1: tiny + universally useful (recommended-on by default).
## Tier 2: useful for specific domains, modest load time.
## Tier 3: heavy / specialist.
const KNOWN := [
	# tier 1
	{"name": "odesolve",  "tier": 1, "desc": "ODE solver — `odesolve(...)`"},
	{"name": "taylor",    "tier": 1, "desc": "Taylor series — `taylor(...)`"},
	{"name": "limits",    "tier": 1, "desc": "Symbolic limits — `limit(...)`"},
	{"name": "defint",    "tier": 1, "desc": "Definite integration with bounds"},
	{"name": "specfn",    "tier": 1, "desc": "Bessel, Gamma, error fns, etc."},
	{"name": "sum",       "tier": 1, "desc": "Symbolic summation — `sum(...)`"},
	{"name": "rlfi",      "tier": 1, "desc": "LaTeX output via `on latex`"},
	{"name": "roots",     "tier": 1, "desc": "Polynomial root finding"},
	# tier 2
	{"name": "laplace",   "tier": 2, "desc": "Laplace transforms (and inverse)"},
	{"name": "ztrans",    "tier": 2, "desc": "Z-transforms"},
	{"name": "assist",    "tier": 2, "desc": "Misc helpers (operators, sets, …)"},
	{"name": "linalg",    "tier": 2, "desc": "Extended matrix algebra"},
	{"name": "normform",  "tier": 2, "desc": "Matrix normal forms (Jordan / Smith)"},
	{"name": "residue",   "tier": 2, "desc": "Residues for contour integration"},
	{"name": "numeric",   "tier": 2, "desc": "Numerical evaluation helpers"},
	{"name": "rataprx",   "tier": 2, "desc": "Rational (Padé / Chebyshev) approx."},
	{"name": "tps",       "tier": 2, "desc": "Truncated power-series arithmetic"},
	{"name": "arnum",     "tier": 2, "desc": "Algebraic numbers, extension fields"},
	{"name": "algint",    "tier": 2, "desc": "Algebraic-function integration"},
	# tier 3
	{"name": "groebner",  "tier": 3, "desc": "Gröbner bases for ideal computation"},
	{"name": "redlog",    "tier": 3, "desc": "Quantifier elimination over real/integer/p-adic"},
	{"name": "excalc",    "tier": 3, "desc": "Exterior calculus / differential forms"},
]

## The set used when no user config exists yet — tier-1 only.
const DEFAULT_SELECTED := [
	"odesolve", "taylor", "limits", "defint", "specfn", "sum", "roots",
	# `rlfi` deliberately *not* on by default — turning it on changes how the
	# engine echoes expressions for some operations. Users opt in.
]


## Read the currently-selected package names. Falls back to DEFAULT_SELECTED
## if the file is missing, malformed, or empty.
static func load_selected() -> Array:
	var cfg := ConfigFile.new()
	var err := cfg.load(PATH)
	if err != OK:
		return DEFAULT_SELECTED.duplicate()
	var stored = cfg.get_value("user", "names", null)
	if stored == null or not (stored is Array) or (stored as Array).is_empty():
		return DEFAULT_SELECTED.duplicate()
	# Filter to known names so a corrupted file can't break the engine init.
	var known_names := PackedStringArray()
	for k in KNOWN:
		known_names.append(k["name"])
	var out: Array = []
	for n in stored:
		if n is String and known_names.has(n):
			out.append(n)
	return out


static func save_selected(names: Array) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("user", "names", names)
	cfg.save(PATH)


## Build the chunk of REDUCE source that loads each selected package on a
## single line. Used by math_engine.gd at session start.
static func to_load_block(names: Array) -> String:
	var parts := PackedStringArray()
	for n in names:
		parts.append("load_package %s" % n)
	if parts.is_empty():
		return ""
	return "; ".join(parts) + ";"
