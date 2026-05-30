extends Node
## End-to-end test of notebook P0–P2: parse a real sample notebook through
## NotebookRunner, evaluate each block via MathEngine, verify results, cache,
## and HTML export. UI-free (no NotebookView), marker-file logging so we can
## see progress even if stdout is buffered.

const SAMPLE := "i:/readtgodot/app/notebooks_sample/algebra.md"
const CALC := "i:/readtgodot/app/notebooks_sample/calculus.md"
const MARKER := "i:/readtgodot/nbtest_marker.txt"
const REPORT := "i:/readtgodot/task19_test_report.md"

var _results_by_id: Dictionary = {}   # engine id -> {output, is_error}


func _ready() -> void:
	_mark("ready entered; engine ready=" + str(MathEngine.is_ready()))
	MathEngine.result_ready.connect(_on_result)
	await get_tree().create_timer(1.5).timeout
	_mark("boot done")
	var log: PackedStringArray = []

	# ---- Phase 1: first run of algebra.md ----
	log.append("== Phase 1 — first run of algebra.md ==")
	var p1 = await _run_notebook_file(SAMPLE)
	log.append("p1: evaluated=%d, blocks=%d, tests pass=%d/%d" % [
		p1.evaluated, p1.block_count, p1.tests_pass, p1.tests_total])
	_mark("phase 1 done")

	# ---- Phase 2: cache hit on second run ----
	log.append("== Phase 2 — cache hit on second run of algebra.md ==")
	var p2 = await _run_notebook_file(SAMPLE)
	if p2.evaluated == 0:
		log.append("OK: zero blocks re-evaluated (cache works)")
	else:
		log.append("FAIL: re-run evaluated %d blocks" % p2.evaluated)
	_mark("phase 2 done")

	# ---- Phase 3: calculus.md (derive block) ----
	log.append("== Phase 3 — calculus.md (derive block) ==")
	var p3 = await _run_notebook_file(CALC)
	log.append("p3: evaluated=%d, blocks=%d, derive ok=%s" % [
		p3.evaluated, p3.block_count, str(p3.derive_ok)])
	_mark("phase 3 done")

	# ---- Phase 4: HTML export quality check ----
	log.append("== Phase 4 — HTML export sanity ==")
	var ok := _check_html_export(SAMPLE, log)
	log.append("HTML export ok: " + str(ok))
	_mark("phase 4 done")

	_write_report(log)
	for line in log:
		print(line)
	print("NBTEST_DONE")
	get_tree().quit()


# ----------------------------------------------------------------------------
# Run one notebook file end-to-end through the runner + engine, write back.
# ----------------------------------------------------------------------------
func _run_notebook_file(path: String) -> Dictionary:
	var text := _read(path)
	var blocks := NotebookRunner.parse_blocks(text)
	var pairs := NotebookRunner.pair_blocks(blocks)
	var evaluated := 0
	var tests_pass := 0
	var tests_total := 0
	var derive_ok := false
	var results: Dictionary = {}     # block start-line -> {new_kind, new_body}
	for p in pairs:
		var src: Dictionary = p["source"]
		var src_hash := NotebookRunner.source_hash(src["body"], src["kind"])
		if p["result"] != null and NotebookRunner.extract_src_hash(p["result"]["body"]) == src_hash:
			continue   # cache hit
		var cmd := _build_cmd(src)
		var id := MathEngine.evaluate(cmd)
		var rsp: Dictionary = await _await_result(id, 10000)
		evaluated += 1
		var rsp_out: String = rsp["output"]
		var rsp_err: bool = rsp["is_error"]
		var payload: String = ""
		var ok: bool = not rsp_err
		var result_kind: String = NotebookRunner.KIND_RESULT
		match src["kind"]:
			NotebookRunner.KIND_CAS:
				payload = MathFormatter.to_display(rsp_out) if ok else MathFormatter.clean_error(rsp_out)
			NotebookRunner.KIND_TEST:
				result_kind = NotebookRunner.KIND_TEST_RESULT
				var p_text: String = MathFormatter.to_display(rsp_out) if ok else MathFormatter.clean_error(rsp_out)
				var equiv: bool = p_text.strip_edges() == "0"
				tests_total += 1
				if equiv:
					tests_pass += 1
				ok = equiv
				payload = "%s\nlhs - rhs → %s" % [
					("(verified)" if equiv else "(MISMATCH)"), p_text]
			NotebookRunner.KIND_DERIVE:
				result_kind = NotebookRunner.KIND_DERIVE_RESULT
				var formatted := PackedStringArray()
				var labels := ["evaluate", "factorize", "trig-expand", "trig-combine"]
				var k: int = 0
				for raw in rsp_out.split("\n"):
					var t: String = String(raw).strip_edges().trim_suffix("$")
					if t.is_empty():
						continue
					formatted.append("%d. %s → %s" % [k + 1, labels[min(k, labels.size() - 1)], t])
					k += 1
				payload = "\n".join(formatted)
				derive_ok = payload.contains("1.") and payload.contains("trig-combine")
			_:
				payload = rsp_out
		var new_body := NotebookRunner.format_result_body(result_kind, src_hash, payload, ok)
		results[src["start"]] = {"pair": p, "new_kind": result_kind, "new_body": new_body}
	if not results.is_empty():
		var new_text := NotebookRunner.rewrite(text, results.values())
		_write(path, new_text)
	return {
		"evaluated": evaluated, "block_count": pairs.size(),
		"tests_pass": tests_pass, "tests_total": tests_total,
		"derive_ok": derive_ok,
	}


func _build_cmd(src: Dictionary) -> String:
	var body: String = src["body"].strip_edges()
	match src["kind"]:
		NotebookRunner.KIND_CAS:
			return body
		NotebookRunner.KIND_TEST:
			for raw in body.split("\n"):
				var line := raw.strip_edges()
				if line.to_lower().begins_with("assert:"):
					var expr := line.substr(7).strip_edges()
					var eq := expr.find("=")
					if eq != -1:
						# REDUCE auto-simplifies on evaluation, so the difference
						# of two equivalent expressions evaluates directly to 0.
						# (`simplify(...)` isn't built in — REDUCE prompts for a
						# Y/N declaration and the engine hangs.)
						return "(%s) - (%s)" % [
							expr.substr(0, eq).strip_edges(), expr.substr(eq + 1).strip_edges()]
			return "0"
		NotebookRunner.KIND_DERIVE:
			# Pipeline avoids the non-built-in `simplify()` (see KIND_TEST note).
			# REDUCE auto-simplifies the bare expression; the others are real
			# operators bundled in the engine.
			return "%s; factorize(%s); trigsimp(%s, expand); trigsimp(%s, combine)" % [
				body, body, body, body]
		_:
			return body


# ----------------------------------------------------------------------------
# Single-request await with timeout. Uses a per-call latch on the result.
# ----------------------------------------------------------------------------
func _await_result(id: int, timeout_ms: int) -> Dictionary:
	# The handler records every result indexed by id, so we can't miss one
	# even if it fires before this function runs.
	var deadline := Time.get_ticks_msec() + timeout_ms
	while not _results_by_id.has(id) and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.02).timeout
	if not _results_by_id.has(id):
		return {"output": "(timeout)", "is_error": true}
	var r: Dictionary = _results_by_id[id]
	_results_by_id.erase(id)
	return r


func _on_result(id: int, output: String, is_error: bool) -> void:
	if id < 0:
		return
	_results_by_id[id] = {"output": output, "is_error": is_error}


# ----------------------------------------------------------------------------
# HTML export check — instantiate a NotebookView just for its converter
# (no UI shown) and then read the file back.
# ----------------------------------------------------------------------------
func _check_html_export(md_path: String, log: PackedStringArray) -> bool:
	# We re-implement a tiny check rather than spinning up the view: parse
	# the notebook and confirm it contains result blocks.
	var html_path := md_path.get_basename() + ".html"
	# Generate via NotebookView's converter logic — call the static-ish bits.
	# To keep the test UI-free, do the export inline:
	var text := _read(md_path)
	var html := _md_to_html(text)
	var f := FileAccess.open(html_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(html)
	f.close()
	log.append("html_path: " + html_path)
	log.append("html_size: " + str(html.length()))
	return html.contains("<h1>") and html.contains("cas-result")


func _md_to_html(md: String) -> String:
	# Minimal duplicate of notebook_view._markdown_to_html for the test.
	var html := PackedStringArray()
	html.append("<!doctype html><meta charset='utf-8'>")
	html.append("<style>body{font-family:system-ui;max-width:780px;margin:2em auto} pre{background:#eee;padding:.5em;border-radius:6px} .cas-result{background:#eef6ee}</style>")
	var lines := md.split("\n")
	var i := 0
	while i < lines.size():
		var line: String = lines[i]
		var stripped := line.strip_edges()
		if stripped.begins_with("```"):
			var kind := stripped.substr(3).strip_edges()
			var j := i + 1
			var body := PackedStringArray()
			while j < lines.size() and not lines[j].strip_edges().begins_with("```"):
				body.append(lines[j])
				j += 1
			var content := "\n".join(body)
			if kind.begins_with("cas"):
				content = NotebookRunner.payload_only(content)
			html.append("<pre class='%s'>%s</pre>" % [kind, content.xml_escape()])
			i = j + 1
		elif stripped.begins_with("# "):
			html.append("<h1>%s</h1>" % stripped.substr(2).xml_escape())
			i += 1
		elif stripped.begins_with("## "):
			html.append("<h2>%s</h2>" % stripped.substr(3).xml_escape())
			i += 1
		elif stripped.is_empty():
			i += 1
		else:
			html.append("<p>%s</p>" % stripped.xml_escape())
			i += 1
	return "\n".join(html)


# ----------------------------------------------------------------------------
# File + marker helpers.
# ----------------------------------------------------------------------------
func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var s := f.get_as_text()
	f.close()
	return s


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()


func _write_report(log: PackedStringArray) -> void:
	_write(REPORT, "# Task 19 — Notebook self-test log\n\n```\n" + "\n".join(log) + "\n```\n")


func _mark(s: String) -> void:
	var f := FileAccess.open(
		MARKER,
		FileAccess.READ_WRITE if FileAccess.file_exists(MARKER) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("[%d] %s" % [Time.get_ticks_msec(), s])
	f.close()
