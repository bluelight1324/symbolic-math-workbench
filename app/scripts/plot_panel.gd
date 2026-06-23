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
	var r := get_rect()
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), _bg)

	# No grid / axes when there's nothing to plot — keeps the panel clean
	# until the user actually requests a plot (task 26).
	if _samples.is_empty():
		return

	# Task 136 — zoom: magnify everything below about the panel centre. The bg
	# above is drawn unscaled; clip_contents (set by the caller) hides overflow.
	if not is_equal_approx(_zoom, 1.0):
		draw_set_transform(size * 0.5 * (1.0 - _zoom), 0.0, Vector2(_zoom, _zoom))

	# Determine y-range from data (fallback to symmetric range).
	var y_min := -10.0
	var y_max := 10.0
	if _samples.size() > 0:
		y_min = _samples[0]
		y_max = _samples[0]
		for v in _samples:
			if is_finite(v):
				y_min = min(y_min, v)
				y_max = max(y_max, v)
		if is_equal_approx(y_min, y_max):
			y_min -= 1.0
			y_max += 1.0
		var pad := (y_max - y_min) * 0.1
		y_min -= pad
		y_max += pad

	# Gridlines.
	for i in range(1, 10):
		var gx := w * i / 10.0
		draw_line(Vector2(gx, 0), Vector2(gx, h), _grid_color, 1.0)
		var gy := h * i / 10.0
		draw_line(Vector2(0, gy), Vector2(w, gy), _grid_color, 1.0)

	# Axes (x=0 and y=0 if within range). Task 136 — thicker for clarity.
	if y_min < 0.0 and y_max > 0.0:
		var ay := h - (0.0 - y_min) / (y_max - y_min) * h
		draw_line(Vector2(0, ay), Vector2(w, ay), _axis_color, 3.0)
	if _x_min < 0.0 and _x_max > 0.0:
		var ax := (0.0 - _x_min) / (_x_max - _x_min) * w
		draw_line(Vector2(ax, 0), Vector2(ax, h), _axis_color, 3.0)

	# Curve.
	if _samples.size() >= 2:
		var pts := PackedVector2Array()
		var n := _samples.size()
		for i in range(n):
			var v: float = _samples[i]
			if not is_finite(v):
				continue   # skip discontinuities (task-4 §5)
			var px := float(i) / float(n - 1) * w
			var py := h - (v - y_min) / (y_max - y_min) * h
			pts.append(Vector2(px, py))
		if pts.size() >= 2:
			draw_polyline(pts, _curve_color, 3.5, true)   # task 136 — bolder curve
