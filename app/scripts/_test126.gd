extends RefCounted
## Task 127 — test harness for the task-126 features. Invoked from main.gd when
## the app is launched with `--test126` (autoloads must be loaded, so it can't
## run via `-s` script mode). Instantiates a NotebookView without the scene tree
## and exercises the pure logic plus UI-state methods with manually-set members.

static func run() -> void:
	var nv = NotebookView.new()
	nv._status = Label.new()   # methods touch _status; give it one (no _ready here)
	var st := {"pass": 0, "fail": 0, "fails": []}
	var ck := func(name: String, got, want):
		if str(got) == str(want):
			st["pass"] += 1
			print("  PASS  ", name)
		else:
			st["fail"] += 1
			st["fails"].append(name)
			print("  FAIL  ", name, "\n          got : ", got, "\n          want: ", want)
	var ckt := func(name: String, cond: bool):
		if cond:
			st["pass"] += 1
			print("  PASS  ", name)
		else:
			st["fail"] += 1
			st["fails"].append(name)
			print("  FAIL  ", name)

	print("=== LaTeX → REDUCE conversion ===")
	ck.call("noop (plain REDUCE)", nv._latex_to_reduce("(x+1)^2"), "(x+1)^2")
	ck.call("fraction", nv._latex_to_reduce("\\frac{1}{2}"), "((1)/(2))")
	ck.call("sqrt", nv._latex_to_reduce("\\sqrt{x}"), "sqrt(x)")
	ck.call("superscript braces", nv._latex_to_reduce("x^{2}"), "x^(2)")
	ck.call("definite integral + implicit mult",
		nv._latex_to_reduce("\\int_{0}^{x} (x-t)\\sin(t)^{3} \\, dt"),
		"int((x-t)*sin(t)^(3), t, 0, x)")
	ck.call("\\cdot operator", nv._latex_to_reduce("\\sin(x)\\cdot\\cos(x)"), "sin(x)*cos(x)")
	ck.call("infinity", nv._latex_to_reduce("\\infty"), "infinity")
	ck.call("greek name", nv._latex_to_reduce("\\alpha+\\beta"), "alpha+beta")
	ck.call("nested frac in int",
		nv._latex_to_reduce("\\int_{0}^{1} \\frac{1}{1+x^{2}} \\, dx"),
		"int(((1)/(1+x^(2))), x, 0, 1)")

	print("=== ^ → pow (3D Expression evaluator) ===")
	ck.call("simple power", nv._pow_to_func("x^2"), "pow(x,2)")
	ck.call("func power", nv._pow_to_func("sin(x)^2"), "pow(sin(x),2)")
	ck.call("paren power", nv._pow_to_func("(x+y)^2"), "pow((x+y),2)")
	ck.call("nested-paren power (149.5)",
		nv._pow_to_func("(sqrt(x*x+y*y)-1.6)^2"), "pow((sqrt(x*x+y*y)-1.6),2)")

	print("=== implicit multiplication ===")
	ck.call("paren-paren", nv._insert_implicit_mult("(a)(b)"), "(a)*(b)")
	ck.call("digit-letter", nv._insert_implicit_mult("2x"), "2*x")
	ck.call("function untouched", nv._insert_implicit_mult("sin(x)"), "sin(x)")

	print("=== wikilinks ===")
	var wl = nv._linkify_wikilinks("see [[foo]] and [[bar]]")
	ckt.call("foo link", wl.find("[url=foo]") != -1)
	ckt.call("bar link", wl.find("[url=bar]") != -1)
	ck.call("no-link passthrough", nv._linkify_wikilinks("plain text"), "plain text")

	print("=== clear outputs (strip *-result blocks) ===")
	var nb := "# t\n\n```cas\n1+1\n```\n```cas-result\n<!-- src-hash: x -->\n2\n```\n\nbye"
	var stripped = nv._strip_result_blocks(nb)
	ckt.call("result block removed", stripped.find("cas-result") == -1)
	ckt.call("source block kept", stripped.find("```cas\n1+1") != -1)
	ckt.call("prose kept", stripped.find("bye") != -1)

	print("=== workspace file collection + search ===")
	var ws := ProjectSettings.globalize_path("res://notebooks_sample")
	var files: Array = []
	nv._collect_md_files(ws, files)
	ckt.call("found >= 8 .md files", files.size() >= 8)
	var has_algebra := false
	for f in files:
		if String(f).ends_with("algebra.md"):
			has_algebra = true
	ckt.call("found algebra.md", has_algebra)
	nv._workspace_dir = ws
	nv._search_input = LineEdit.new()
	nv._search_results = ItemList.new()
	nv._search_input.text = "integral"
	nv._run_workspace_search()
	ckt.call("search 'integral' finds hits", nv._search_hits.size() > 0)

	print("=== distraction-free toggle ===")
	nv._sidebar_col = VBoxContainer.new()
	nv._popup = null
	nv._toggle_distraction_free()
	ckt.call("zen on hides sidebar", nv._zen_on and not nv._sidebar_col.visible)
	nv._toggle_distraction_free()
	ckt.call("zen off shows sidebar", (not nv._zen_on) and nv._sidebar_col.visible)

	print("=== 3D surface builder ===")
	nv._color_scheme = {"src_bg": Color.WHITE, "text": Color.BLACK, "muted": Color.GRAY,
		"res_bg": Color(0.96, 0.96, 0.98), "res_border": Color(0.8, 0.8, 0.85),
		"res_chip": Color(0.2, 0.4, 0.7)}
	nv._density = {"chip_size": 24, "chip_offset": 4, "corner_radius": 6, "cell_padding": 8,
		"border_width": 1}
	var good = nv._build_surface3d("z = sin(x)*cos(y)")
	# Task 136 — now wrapped with a control bar in a VBox (was a bare SubViewportContainer).
	ckt.call("valid expr → VBox wrapper", good is VBoxContainer)
	var bad = nv._build_surface3d("z = @@@nonsense(")
	ckt.call("bad expr → Label fallback", bad is Label)

	print("=== task 136-143 — 3D plot structure, scroll/rotate, contour shader ===")
	ckt.call("wrapper has controls + stack", good.get_child_count() == 2)
	var stack3 = good.get_child(1)
	ckt.call("stack has viewport + drag overlay", stack3.get_child_count() == 2)
	var cont3 = stack3.get_child(0)
	ckt.call("viewport is SubViewportContainer", cont3 is SubViewportContainer)
	ckt.call("task137: viewport IGNOREs mouse (wheel passes)",
		cont3.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	ckt.call("task137: stack IGNOREs mouse (wheel passes)",
		stack3.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	ckt.call("task142: drag overlay is PASS (rotate + scroll)",
		stack3.get_child(1).mouse_filter == Control.MOUSE_FILTER_PASS)
	var mi3 = null
	for c in cont3.get_child(0).get_child(0).get_children():   # vp -> world -> children
		if c is MeshInstance3D and c.mesh is ArrayMesh:        # the surface (not the axes box)
			mi3 = c
			break
	ckt.call("surface mesh present", mi3 != null)
	var smat = null
	if mi3 != null and mi3.mesh != null:
		smat = mi3.mesh.surface_get_material(0)
	ckt.call("task143: surface uses contour ShaderMaterial", smat is ShaderMaterial)
	ckt.call("task143: shader code has contour math", smat != null \
		and smat.shader != null and smat.shader.code.find("fract(s)") != -1)

	print("=== task 136 — 2D plot zoom ===")
	var pp = preload("res://scripts/plot_panel.gd").new()
	pp.zoom_in()
	ckt.call("zoom_in increases zoom", pp._zoom > 1.0)
	pp.zoom_out(); pp.zoom_out()
	ckt.call("zoom_out decreases zoom", pp._zoom < 1.0)
	pp.zoom_reset()
	ckt.call("zoom_reset → 1.0", is_equal_approx(pp._zoom, 1.0))
	pp.free()

	print("=== task 148.5 — Viridis colormap + 2D ticks/format ===")
	var c0: Color = nv._viridis(0.0)
	var c1: Color = nv._viridis(1.0)
	ckt.call("viridis(0) is dark", c0.v < 0.5)
	ckt.call("viridis(1) is bright yellow", c1.r > 0.8 and c1.g > 0.8 and c1.b < 0.4)
	var pp2 = preload("res://scripts/plot_panel.gd").new()
	var ticks = pp2._nice_ticks(0.0, 10.0)
	ckt.call("nice_ticks returns several", ticks.size() >= 3)
	ckt.call("nice_ticks within range", ticks[0] >= 0.0 and ticks[ticks.size() - 1] <= 10.0)
	ck.call("fmt(3.14159) → 3.14", pp2._fmt(3.14159), "3.14")
	ck.call("fmt(0) → 0", pp2._fmt(0.0), "0")
	pp2.free()

	print("=== task 148.6 — parametric surfaces + 3D scene additions ===")
	var psurf = nv._build_parametric3d("x = cos(u)*(2+cos(v))\ny = sin(u)*(2+cos(v))\nz = sin(v)")
	ckt.call("parametric → VBox wrapper", psurf is VBoxContainer)
	ckt.call("bad parametric → Label", nv._build_parametric3d("nonsense") is Label)
	var pmi = null
	for c in psurf.get_child(1).get_child(0).get_child(0).get_child(0).get_children():
		if c is MeshInstance3D and c.mesh is ArrayMesh:
			pmi = c
			break
	ckt.call("parametric surface mesh present", pmi != null)
	ckt.call("parametric uses contour ShaderMaterial",
		pmi != null and pmi.mesh.surface_get_material(0) is ShaderMaterial)
	# the height-field 3D scene now also carries an axes box + a colour-bar
	var hf = nv._build_surface3d("z = sin(x)*cos(y)")
	var mesh_count := 0
	for c in hf.get_child(1).get_child(0).get_child(0).get_child(0).get_children():
		if c is MeshInstance3D:
			mesh_count += 1
	ckt.call("3D scene has surface + axes box + colour-bar (>=3 meshes)", mesh_count >= 3)

	print("=== task 148.6 — cas-surface block recognition ===")
	var sblocks = NotebookRunner.parse_blocks("```cas-surface\nx=1\ny=1\nz=1\n```")
	ckt.call("parser recognises cas-surface",
		sblocks.size() == 1 and sblocks[0]["kind"] == "cas-surface")
	var spairs = NotebookRunner.pair_blocks(sblocks)
	ckt.call("pair_blocks makes cas-surface runnable",
		spairs.size() == 1 and spairs[0]["source"]["kind"] == "cas-surface")

	print("=== task 149.3 — animated surfaces + vector fields ===")
	ckt.call("anim → VBox wrapper", nv._build_anim3d("z = sin(x + t)*cos(y)") is VBoxContainer)
	ckt.call("bad anim → Label", nv._build_anim3d("@@@") is Label)
	ckt.call("field → VBox wrapper", nv._build_field3d("u = -y\nv = x\nw = 0") is VBoxContainer)
	ckt.call("bad field → Label", nv._build_field3d("nonsense") is Label)
	for k in ["cas-anim", "cas-field"]:
		var bl = NotebookRunner.parse_blocks("```%s\nz=1\n```" % k)
		ckt.call("parser recognises %s" % k, bl.size() == 1 and bl[0]["kind"] == k)
		ckt.call("pair_blocks runnable %s" % k, NotebookRunner.pair_blocks(bl).size() == 1)

	print("=== task 149.5 / 253.0 — implicit surfaces (Surface Nets, threaded) ===")
	# Task 253.0 — the builder now returns an async placeholder cell; the heavy
	# Surface-Nets work lives in _implicit_mesh (tested directly here).
	ckt.call("implicit sphere → async cell", nv._build_implicit3d("x*x + y*y + z*z - 4") is PanelContainer)
	ckt.call("implicit torus (nested ^) → async cell",
		nv._build_implicit3d("(sqrt(x*x + y*y) - 1.6)^2 + z*z - 0.5") is PanelContainer)
	ckt.call("bad implicit → Label", nv._build_implicit3d("@@@(") is Label)
	ckt.call("_implicit_surftool sphere → SurfaceTool", nv._implicit_surftool("x*x+y*y+z*z-4", 2.6, 20) is SurfaceTool)
	ckt.call("_implicit_surftool no-crossing → null", nv._implicit_surftool("x*x+y*y+z*z+9", 2.6, 20) == null)
	var iblk = NotebookRunner.parse_blocks("```cas-implicit\nx*x+y*y+z*z-4\n```")
	ckt.call("parser recognises cas-implicit", iblk.size() == 1 and iblk[0]["kind"] == "cas-implicit")
	ckt.call("pair_blocks runnable cas-implicit", NotebookRunner.pair_blocks(iblk).size() == 1)

	print("=== task 251.0 — 2D multi-series ===")
	ckt.call("_plot_exprs splits lines", nv._plot_exprs("sin(x)\ncos(x)").size() == 2)
	ckt.call("_plot_exprs skips comments/blanks", nv._plot_exprs("# c\nsin(x)\n\n").size() == 1)
	ckt.call("_plot_exprs fallback for blank body", nv._plot_exprs("   ").size() == 1)
	var grps := nv._extract_brace_groups("foo {1,2,3} bar {4,5} baz")
	ckt.call("brace groups found", grps.size() == 2)
	ck.call("first brace group", str(grps[0]), "{1,2,3}")
	var pp3 = preload("res://scripts/plot_panel.gd").new()
	pp3.set_series(-10.0, 10.0, [
		{"label": "a", "ys": PackedFloat64Array([1.0, 2.0])},
		{"label": "b", "ys": PackedFloat64Array([3.0, 4.0])}])
	ckt.call("set_series stores 2 series", pp3._series.size() == 2)
	ckt.call("series colours distinct", pp3._series_color(0) != pp3._series_color(1))
	pp3.set_samples(-10.0, 10.0, PackedFloat64Array([1.0]))
	ckt.call("set_samples clears multi-series", pp3._series.is_empty())
	pp3.free()

	print("=== task 251.0 — cas-domain (complex evaluator) ===")
	var ce = preload("res://scripts/complex_eval.gd").new()
	ckt.call("parse z^2-1", ce.parse("z^2 - 1"))
	var r1: Vector2 = ce.eval(Vector2(2.0, 0.0))            # 4-1 = 3
	ckt.call("(z^2-1)|z=2 = 3", is_equal_approx(r1.x, 3.0) and is_zero_approx(r1.y))
	var r2: Vector2 = ce.eval(Vector2(0.0, 1.0))            # i^2-1 = -2
	ckt.call("(z^2-1)|z=i = -2", is_equal_approx(r2.x, -2.0) and is_zero_approx(r2.y))
	var ce2 = preload("res://scripts/complex_eval.gd").new()
	ce2.parse("1/z")
	var r3: Vector2 = ce2.eval(Vector2(0.0, 1.0))           # 1/i = -i
	ckt.call("(1/z)|z=i = -i", is_zero_approx(r3.x) and is_equal_approx(r3.y, -1.0))
	var ce3 = preload("res://scripts/complex_eval.gd").new()
	ce3.parse("exp(z)")
	var r4: Vector2 = ce3.eval(Vector2(0.0, 0.0))           # exp(0) = 1
	ckt.call("exp(0) = 1", is_equal_approx(r4.x, 1.0) and is_zero_approx(r4.y))
	var ce4 = preload("res://scripts/complex_eval.gd").new()
	ckt.call("parse garbage fails", not ce4.parse("@@@"))
	ckt.call("domain → async cell", nv._build_domain2d("z^2 - 1") is PanelContainer)
	ckt.call("bad domain → Label", nv._build_domain2d("@@@(") is Label)
	ckt.call("_domain_image → Image", nv._domain_image("z^2-1", 3.0) is Image)
	ckt.call("domain colour saturated for finite", nv._domain_color(Vector2(1.0, 1.0)).s > 0.5)
	ckt.call("domain colour white at pole", nv._domain_color(Vector2(INF, INF)).s < 0.1)
	var dblk = NotebookRunner.parse_blocks("```cas-domain\nz^2\n```")
	ckt.call("parser recognises cas-domain", dblk.size() == 1 and dblk[0]["kind"] == "cas-domain")
	ckt.call("pair_blocks runnable cas-domain", NotebookRunner.pair_blocks(dblk).size() == 1)

	print("=== task 252.0 — PNG export ===")
	var noop := func(): pass
	var svh := Control.new()
	var svp := SubViewport.new()
	svh.add_child(svp)
	ckt.call("_find_subviewport locates viewport", nv._find_subviewport(svh) == svp)
	ckt.call("_find_subviewport null when absent", nv._find_subviewport(Control.new()) == null)
	var trh := Control.new()
	var trr := TextureRect.new()
	trh.add_child(trr)
	ckt.call("_find_texrect locates texture rect", nv._find_texrect(trh) == trr)
	var pbtn = nv._png_btn(Control.new(), "x")
	ckt.call("_png_btn → Button", pbtn is Button)
	var zb_plain = nv._make_zoom_bar(noop, noop, noop)
	var zb_exp = nv._make_zoom_bar(noop, noop, noop, Control.new(), "x")
	ckt.call("export target adds a PNG button to the bar",
		zb_exp.get_child_count() == zb_plain.get_child_count() + 1)
	svh.free(); trh.free(); pbtn.free(); zb_plain.free(); zb_exp.free()

	print("=== task 253.0 — threaded async plot wrapper ===")
	var ap = nv._async_plot("test", func(): return 0, func(_d): return Label.new())
	ckt.call("_async_plot → cell", ap is PanelContainer)
	ckt.call("cell has chip + slot", ap.get_child(0).get_child_count() == 2)
	ckt.call("detached build runs synchronously (finish applied)",
		ap.get_child(0).get_child(1).get_child_count() == 1)
	ap.free()

	# ----------------------------------------------------------------------------
	# Task 253.1 — thorough pass over the plotting features (251.0 / 252.0 / 253.0).
	# ----------------------------------------------------------------------------
	print("=== task 253.1 — thorough: complex evaluator arithmetic ===")
	var ce_zz = preload("res://scripts/complex_eval.gd").new(); ce_zz.parse("z*z")
	ckt.call("(z*z)|1+i = 2i", ce_zz.eval(Vector2(1, 1)).is_equal_approx(Vector2(0, 2)))
	var ce_sq = preload("res://scripts/complex_eval.gd").new(); ce_sq.parse("sqrt(z)")
	ckt.call("sqrt(4) = 2", ce_sq.eval(Vector2(4, 0)).is_equal_approx(Vector2(2, 0)))
	var ce_sin = preload("res://scripts/complex_eval.gd").new(); ce_sin.parse("sin(z)")
	ckt.call("sin(0) = 0", ce_sin.eval(Vector2(0, 0)).is_equal_approx(Vector2.ZERO))
	var ce_cos = preload("res://scripts/complex_eval.gd").new(); ce_cos.parse("cos(z)")
	ckt.call("cos(0) = 1", ce_cos.eval(Vector2(0, 0)).is_equal_approx(Vector2(1, 0)))
	var ce_im = preload("res://scripts/complex_eval.gd").new(); ce_im.parse("2z")
	ckt.call("implicit mult 2z|3 = 6", ce_im.eval(Vector2(3, 0)).is_equal_approx(Vector2(6, 0)))
	var ce_cj = preload("res://scripts/complex_eval.gd").new(); ce_cj.parse("conj(z)")
	ckt.call("conj(1+2i) = 1-2i", ce_cj.eval(Vector2(1, 2)).is_equal_approx(Vector2(1, -2)))
	var ce_eu = preload("res://scripts/complex_eval.gd").new(); ce_eu.parse("exp(i*pi)")
	var eu: Vector2 = ce_eu.eval(Vector2(0, 0))
	ckt.call("exp(i*pi) ≈ -1", is_equal_approx(eu.x, -1.0) and absf(eu.y) < 1e-6)
	var ce_neg = preload("res://scripts/complex_eval.gd").new(); ce_neg.parse("-z")
	ckt.call("unary minus -z|2 = -2", ce_neg.eval(Vector2(2, 0)).is_equal_approx(Vector2(-2, 0)))
	var ce_d0 = preload("res://scripts/complex_eval.gd").new(); ce_d0.parse("1/z")
	ckt.call("1/0 → non-finite", not is_finite(ce_d0.eval(Vector2(0, 0)).x))
	ckt.call("unbalanced parens rejected", not preload("res://scripts/complex_eval.gd").new().parse("(z+1"))
	ckt.call("empty expression rejected", not preload("res://scripts/complex_eval.gd").new().parse(""))

	print("=== task 253.1 — thorough: 2D multi-series helpers ===")
	ckt.call("_plot_exprs 3 lines past blanks+comments",
		nv._plot_exprs("sin(x)\n\n# note\ncos(x)\ntan(x)\n").size() == 3)
	var grp2 := nv._extract_brace_groups("{1,2} {{3},{4}} {5}")
	ckt.call("brace groups top-level count == 3", grp2.size() == 3)
	ck.call("nested group captured whole", str(grp2[1]), "{{3},{4}}")
	ckt.call("no braces → no groups", nv._extract_brace_groups("no lists here").is_empty())

	print("=== task 253.1 — thorough: domain image + colour ===")
	var dimg: Image = nv._domain_image("z*z - 1", 3.0)
	ckt.call("domain image is 280×280", dimg.get_width() == 280 and dimg.get_height() == 280)
	ckt.call("domain image is RGB8", dimg.get_format() == Image.FORMAT_RGB8)
	ckt.call("colour near a zero is dark", nv._domain_color(Vector2(0.001, 0.0)).v < 0.55)
	ckt.call("colour for large |w| is brighter", nv._domain_color(Vector2(100.0, 0.0)).v > 0.6)

	print("=== task 253.1 — thorough: implicit worker + finish ===")
	ckt.call("_implicit_surftool plane (f=z) → SurfaceTool", nv._implicit_surftool("z", 2.6, 16) is SurfaceTool)
	ckt.call("_implicit_finish(null) → Label", nv._implicit_finish(null, 2.6) is Label)
	var st_sphere = nv._implicit_surftool("x*x+y*y+z*z-4", 2.6, 20)
	ckt.call("_implicit_finish(SurfaceTool) → 3D scene VBox", nv._implicit_finish(st_sphere, 2.6) is VBoxContainer)

	print("=== task 253.1 — thorough: export plumbing + async detached ===")
	var deep := Control.new(); var mid := Control.new(); var sv2 := SubViewport.new()
	deep.add_child(mid); mid.add_child(sv2)
	ckt.call("_find_subviewport finds deeply-nested viewport", nv._find_subviewport(deep) == sv2)
	deep.free()
	var apc = nv._async_plot("c", func(): return "DATA",
		func(d): var l := Label.new(); l.text = str(d); return l)
	var slot_node = apc.get_child(0).get_child(1)
	ckt.call("detached async applies finish to slot",
		slot_node.get_child_count() == 1 and slot_node.get_child(0) is Label)
	ck.call("detached async threads data through", (slot_node.get_child(0) as Label).text, "DATA")
	apc.free()

	nv.free()
	print("\n==================================================")
	print("RESULT: %d passed, %d failed" % [st["pass"], st["fail"]])
	if st["fail"] > 0:
		print("FAILURES: ", ", ".join(st["fails"]))
	print("==================================================")
