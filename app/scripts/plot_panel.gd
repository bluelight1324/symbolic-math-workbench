extends Control
## Plot panel — custom 2D drawing of sampled function(s) (task-2 §4, task-4 §5).
## Receives y-samples over a fixed x-range and draws axes + antialiased curves.
## Task 251.0 — supports MULTIPLE series (one curve per expression) + a legend.

var _x_min := -10.0
var _x_max := 10.0
var _samples := PackedFloat64Array()        # single-series path (back-compat)
var _series: Array = []                       # task 251.0 — [{ys, label}, …] multi-series
var _axis_color := Color(0.5, 0.55, 0.62)
var _grid_color := Color(0.27, 0.30, 0.36)
var _curve_color := Color(0.36, 0.74, 1.0)
var _bg := Color(0.11, 0.12, 0.15)
var _zoom := 1.0   # task 136 — magnification around the panel centre
var _hover_px := -1.0      # task 148.5 — cursor x for the hover crosshair
var _hover_active := false

# Task 251.0 — distinct, theme-independent colours for multi-series curves.
const SERIES_PALETTE := [
	Color(0.22, 0.55, 1.00),   # blue
	Color(0.95, 0.42, 0.24),   # orange-red
	Color(0.28, 0.74, 0.36),   # green
	Color(0.76, 0.42, 0.86),   # purple
	Color(0.95, 0.72, 0.16),   # amber
	Color(0.22, 0.72, 0.70),   # teal
]


func _ready() -> void:
	# Task 148.5 (req 2D2) — receive hover motion, but PASS the wheel so the
	# notebook page still scrolls over the plot (task 137).
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_px = event.position.x
		_hover_active = true
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover_active = false
		queue_redraw()


## Task 136 — zoom the plot in / out (uniform magnification about the centre).
func zoom_in() -> void:
	_zoom = minf(_zoom * 1.3, 30.0)
	queue_redraw()


func zoom_out() -> void:
	_zoom = maxf(_zoom / 1.3, 0.2)
	queue_redraw()


func zoom_reset() -> void:
	_zoom = 1.0
	queue_redraw()


func set_samples(x_min: float, x_max: float, ys: PackedFloat64Array) -> void:
	_x_min = x_min
	_x_max = x_max
	_samples = ys
	_series = []
	queue_redraw()


## Task 251.0 — set several curves at once. `series` is [{label:String, ys:Packed…}].
func set_series(x_min: float, x_max: float, series: Array) -> void:
	_x_min = x_min
	_x_max = x_max
	_series = series
	_samples = PackedFloat64Array()
	queue_redraw()


## Task 99 — let the inline notebook plot adopt the active colour scheme so it
## reads as part of the notebook (e.g. light background + MATLAB-blue curve)
## instead of a fixed dark panel.
func set_theme_colors(bg: Color, axis: Color, grid: Color, curve: Color) -> void:
	_bg = bg
	_axis_color = axis
	_grid_color = grid
	_curve_color = curve
	queue_redraw()


func clear_plot() -> void:
	_samples = PackedFloat64Array()
	_series = []
	queue_redraw()


func _series_color(i: int) -> Color:
	return SERIES_PALETTE[i % SERIES_PALETTE.size()]


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), _bg)

	# One code path: the single-sample case is just a one-element, unlabelled series.
	var multi := not _series.is_empty()
	var series: Array = _series
	if not multi:
		if _samples.is_empty():
			return   # keep the panel clean until there's something to plot (task 26)
		series = [{"ys": _samples, "label": ""}]

	# Combined y-range across every series.
	var y_min := INF
	var y_max := -INF
	for s in series:
		for v in s["ys"]:
			if is_finite(v):
				y_min = minf(y_min, v)
				y_max = maxf(y_max, v)
	if not is_finite(y_min) or not is_finite(y_max):
		return
	if is_equal_approx(y_min, y_max):
		y_min -= 1.0
		y_max += 1.0
	var pad := (y_max - y_min) * 0.1
	y_min -= pad
	y_max += pad

	# --- scaled content (task 136 zoom about the centre) ---
	if not is_equal_approx(_zoom, 1.0):
		draw_set_transform(size * 0.5 * (1.0 - _zoom), 0.0, Vector2(_zoom, _zoom))
	for i in range(1, 10):
		var gx := w * i / 10.0
		draw_line(Vector2(gx, 0), Vector2(gx, h), _grid_color, 1.0)
		var gy := h * i / 10.0
		draw_line(Vector2(0, gy), Vector2(w, gy), _grid_color, 1.0)
	if y_min < 0.0 and y_max > 0.0:
		var ay := h - (0.0 - y_min) / (y_max - y_min) * h
		draw_line(Vector2(0, ay), Vector2(w, ay), _axis_color, 3.0)
	if _x_min < 0.0 and _x_max > 0.0:
		var ax := (0.0 - _x_min) / (_x_max - _x_min) * w
		draw_line(Vector2(ax, 0), Vector2(ax, h), _axis_color, 3.0)
	for si in range(series.size()):
		var ys: PackedFloat64Array = series[si]["ys"]
		if ys.size() < 2:
			continue
		var col: Color = _series_color(si) if multi else _curve_color
		var pts := PackedVector2Array()
		var n := ys.size()
		for i in range(n):
			var v: float = ys[i]
			if not is_finite(v):
				continue   # skip discontinuities (task-4 §5)
			pts.append(Vector2(float(i) / float(n - 1) * w,
				h - (v - y_min) / (y_max - y_min) * h))
		if pts.size() >= 2:
			draw_polyline(pts, col, 3.5, true)   # task 136 — bolder curve

	# --- screen-space overlays: axis tick numbers + legend + hover (task 148.5) ---
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	var fs := 13
	for tv in _nice_ticks(_x_min, _x_max):
		var spx: float = w * 0.5 * (1.0 - _zoom) + _zoom * ((tv - _x_min) / (_x_max - _x_min) * w)
		if spx >= 0.0 and spx <= w - 2.0:
			draw_string(font, Vector2(spx + 2, h - 5), _fmt(tv),
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _axis_color)
	for tv in _nice_ticks(y_min, y_max):
		var spy: float = h * 0.5 * (1.0 - _zoom) + _zoom * (h - (tv - y_min) / (y_max - y_min) * h)
		if spy >= float(fs) and spy <= h:
			draw_string(font, Vector2(3, spy - 2), _fmt(tv),
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _axis_color)

	# Task 251.0 — legend (only when series carry labels).
	if multi:
		_draw_legend(series, font, fs, w)

	# Hover crosshair + per-series read-out.
	if _hover_active:
		_draw_hover(series, multi, y_min, y_max, font, fs, w, h)


## Task 251.0 — draw a legend box (top-right) with a colour swatch + label per series.
func _draw_legend(series: Array, font: FontFile, fs: int, w: float) -> void:
	var labelled := false
	for s in series:
		if String(s["label"]) != "":
			labelled = true
	if not labelled:
		return
	var row_h := fs + 6
	var box_w := 150.0
	var box_h := row_h * series.size() + 8
	# Top-left, inset past the y-axis tick numbers — always on-screen even when a
	# long chip widens the notebook column beyond the window (task 251.0).
	var ox := 46.0
	var oy := 8.0
	# Contrasting fill (tone the bg toward the axis colour) so the box is visible
	# on a light *or* dark theme, with a clear border.
	draw_rect(Rect2(ox, oy, box_w, box_h), _bg.lerp(_axis_color, 0.16))
	draw_rect(Rect2(ox, oy, box_w, box_h), _axis_color, false, 1.5)
	for si in range(series.size()):
		var ry := oy + 4 + si * row_h
		draw_rect(Rect2(ox + 6, ry + 3, 16, fs - 4), _series_color(si))
		var lbl := String(series[si]["label"])
		if lbl.length() > 16:
			lbl = lbl.substr(0, 15) + "…"
		draw_string(font, Vector2(ox + 28, ry + fs), lbl,
			HORIZONTAL_ALIGNMENT_LEFT, box_w - 32, fs, _axis_color)


## Hover read-out: crosshair + a dot on each series at the cursor's x.
func _draw_hover(series: Array, multi: bool, y_min: float, y_max: float,
		font: FontFile, fs: int, w: float, h: float) -> void:
	var first: PackedFloat64Array = series[0]["ys"]
	if first.size() < 2:
		return
	var n2 := first.size()
	var base_px := (_hover_px - w * 0.5 * (1.0 - _zoom)) / _zoom
	var idx := clampi(int(round(base_px / w * (n2 - 1))), 0, n2 - 1)
	var dx := lerpf(_x_min, _x_max, float(idx) / float(n2 - 1))
	draw_line(Vector2(_hover_px, 0), Vector2(_hover_px, h),
		_axis_color * Color(1, 1, 1, 0.7), 1.0)
	for si in range(series.size()):
		var ys: PackedFloat64Array = series[si]["ys"]
		if idx >= ys.size():
			continue
		var dv: float = ys[idx]
		if not is_finite(dv):
			continue
		var col: Color = _series_color(si) if multi else _curve_color
		var spy := h * 0.5 * (1.0 - _zoom) + _zoom * (h - (dv - y_min) / (y_max - y_min) * h)
		draw_circle(Vector2(_hover_px, spy), 4.0, col)
		if not multi:
			draw_string(font, Vector2(clampf(_hover_px + 6, 0, w - 96), 16),
				"(%s, %s)" % [_fmt(dx), _fmt(dv)], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if multi:
		draw_string(font, Vector2(clampf(_hover_px + 6, 0, w - 70), 16),
			"x = %s" % _fmt(dx), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _axis_color)


## Task 148.5 (req A1) — ~6 "nice" tick values (1·2·5 stepping) in [lo, hi].
func _nice_ticks(lo: float, hi: float) -> Array[float]:
	var span := hi - lo
	if span <= 0.0:
		return []
	var raw := span / 6.0
	var mag := pow(10.0, floor(log(raw) / log(10.0)))
	var norm := raw / mag
	var step := mag
	if norm >= 1.5:
		step = mag * 2.0
	if norm >= 3.0:
		step = mag * 5.0
	if norm >= 7.0:
		step = mag * 10.0
	var out: Array[float] = []
	var v: float = ceil(lo / step) * step
	var guard := 0
	while v <= hi + step * 0.001 and guard < 40:
		out.append(v)
		v += step
		guard += 1
	return out


func _fmt(v: float) -> String:
	if absf(v) < 0.0005:
		return "0"
	return String.num(v, 2)
