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
	nv._color_scheme = {"src_bg": Color.WHITE, "text": Color.BLACK}
	var good = nv._build_surface3d("z = sin(x)*cos(y)")
	ckt.call("valid expr → SubViewportContainer", good is SubViewportContainer)
	var bad = nv._build_surface3d("z = @@@nonsense(")
	ckt.call("bad expr → Label fallback", bad is Label)

	nv.free()
	print("\n==================================================")
	print("RESULT: %d passed, %d failed" % [st["pass"], st["fail"]])
	if st["fail"] > 0:
		print("FAILURES: ", ", ".join(st["fails"]))
	print("==================================================")
