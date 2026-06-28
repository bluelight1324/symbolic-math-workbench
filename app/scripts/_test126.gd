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
	nv._color_scheme = {"src_bg": Color.WHITE, "text": Color.BLACK, "muted": Color.GRAY}
	nv._density = {"chip_size": 24, "chip_offset": 4}
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

	nv.free()
	print("\n==================================================")
	print("RESULT: %d passed, %d failed" % [st["pass"], st["fail"]])
	if st["fail"] > 0:
		print("FAILURES: ", ", ".join(st["fails"]))
	print("==================================================")
