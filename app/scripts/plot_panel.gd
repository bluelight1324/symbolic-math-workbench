extends Control
## Plot panel — custom 2D drawing of a sampled function (task-2 §4, task-4 §5).
## Receives y-samples over a fixed x-range and draws axes + an antialiased curve.

var _x_min := -10.0
var _x_max := 10.0
var _samples := PackedFloat64Array()
var _axis_color := Color(0.5, 0.55, 0.62)
var _grid_color := Color(0.27, 0.30, 0.36)
var _curve_color := Color(0.36, 0.74, 1.0)
var _bg := Color(0.11, 0.12, 0.15)
var _zoom := 1.0   # task 136 — magnification around the panel centre
var _hover_px := -1.0      # task 148.5 — cursor x for the hover crosshair
var _hover_active := false


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
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), _bg)

	# Keep the panel clean until there's something to plot (task 26).
	if _samples.is_empty():
		return

	# y-range from the data.
	var y_min := _samples[0]
	var y_max := _samples[0]
	for v in _samples:
		if is_finite(v):
			y_min = minf(y_min, v)
			y_max = maxf(y_max, v)
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
	if _samples.size() >= 2:
		var pts := PackedVector2Array()
		var n := _samples.size()
		for i in range(n):
			var v: float = _samples[i]
			if not is_finite(v):
				continue   # skip discontinuities (task-4 §5)
			pts.append(Vector2(float(i) / float(n - 1) * w,
				h - (v - y_min) / (y_max - y_min) * h))
		if pts.size() >= 2:
			draw_polyline(pts, _curve_color, 3.5, true)   # task 136 — bolder curve

	# --- screen-space overlays: axis tick numbers + hover (task 148.5) ---
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
	if _hover_active and _samples.size() >= 2:
		var n2 := _samples.size()
		var base_px := (_hover_px - w * 0.5 * (1.0 - _zoom)) / _zoom
		var idx := clampi(int(round(base_px / w * (n2 - 1))), 0, n2 - 1)
		var dv: float = _samples[idx]
		if is_finite(dv):
			var dx := lerpf(_x_min, _x_max, float(idx) / float(n2 - 1))
			draw_line(Vector2(_hover_px, 0), Vector2(_hover_px, h),
				_axis_color * Color(1, 1, 1, 0.7), 1.0)
			var spy2 := h * 0.5 * (1.0 - _zoom) + _zoom * (h - (dv - y_min) / (y_max - y_min) * h)
			draw_circle(Vector2(_hover_px, spy2), 4.0, _curve_color)
			draw_string(font, Vector2(clampf(_hover_px + 6, 0, w - 96), 16),
				"(%s, %s)" % [_fmt(dx), _fmt(dv)], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _curve_color)


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
