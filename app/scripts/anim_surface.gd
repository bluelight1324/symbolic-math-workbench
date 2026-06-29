extends MeshInstance3D
## Task 149.3 — an animated z = f(x, y, t) surface. Re-samples f and rebuilds the
## mesh each frame with t = elapsed time (capped to ~25 fps to spare the CPU).
## Pure Godot — Godot's `Expression` evaluator + `SurfaceTool`. Used by
## notebook_view's `cas-anim` plot kind via the shared `_plot3d_scene`.

var expr: Expression                 # parsed with vars ["x", "y", "t"]
var contour_mat: Material            # the shared PBR + contour material
var grid := 34
var lo := -PI
var hi := PI
var _t := 0.0
var _acc := 1.0                       # force a rebuild on the first frame


func _process(delta: float) -> void:
	_t += delta
	_acc += delta
	if _acc < 0.04:                   # ~25 fps update cap
		return
	_acc = 0.0
	_rebuild()


func _rebuild() -> void:
	if expr == null:
		return
	var n := grid
	var stp := (hi - lo) / float(n)
	var h: Array = []
	var zmin := INF
	var zmax := -INF
	for i in range(n + 1):
		var row: Array = []
		for j in range(n + 1):
			var z = expr.execute([lo + i * stp, lo + j * stp, _t])
			var f: float = float(z) if (z is float or z is int) else 0.0
			if is_nan(f) or is_inf(f):
				f = 0.0
			row.append(f)
			zmin = minf(zmin, f)
			zmax = maxf(zmax, f)
		h.append(row)
	var zr := maxf(0.001, zmax - zmin)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(n):
		for j in range(n):
			var p: Array = [_pos(h, i, j, zmin, zr), _pos(h, i + 1, j, zmin, zr),
				_pos(h, i + 1, j + 1, zmin, zr), _pos(h, i, j + 1, zmin, zr)]
			var c: Array = [_col(h, i, j, zmin, zr), _col(h, i + 1, j, zmin, zr),
				_col(h, i + 1, j + 1, zmin, zr), _col(h, i, j + 1, zmin, zr)]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				for k in tri:
					st.set_color(c[k])
					st.add_vertex(p[k])
	st.generate_normals()
	if contour_mat:
		st.set_material(contour_mat)
	mesh = st.commit()


func _pos(h: Array, i: int, j: int, zmin: float, zr: float) -> Vector3:
	return Vector3((float(i) / grid - 0.5) * 4.0,
		(float(h[i][j]) - zmin) / zr * 2.0 - 1.0,
		(float(j) / grid - 0.5) * 4.0)


func _col(h: Array, i: int, j: int, zmin: float, zr: float) -> Color:
	return _viridis((float(h[i][j]) - zmin) / zr)


func _viridis(t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	var s := [Color(0.267, 0.005, 0.329), Color(0.231, 0.318, 0.545),
		Color(0.128, 0.567, 0.551), Color(0.369, 0.789, 0.383),
		Color(0.993, 0.906, 0.144)]
	var seg := t * 4.0
	var i := int(floor(seg))
	if i >= 4:
		return s[4]
	return (s[i] as Color).lerp(s[i + 1] as Color, seg - float(i))
