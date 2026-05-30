class_name NotebookRunner
extends RefCounted
## Parses Markdown notebooks into fenced blocks, hashes sources for the
## content-addressed cache (P1, requirement #5), and produces the rewritten
## text after a run. Pure logic — no engine I/O lives here. The view-layer
## script (notebook_view.gd) drives MathEngine asynchronously and feeds
## results back through `replace_result_block()`.

const KIND_CAS := "cas"
const KIND_RESULT := "cas-result"
const KIND_TEST := "cas-test"
const KIND_TEST_RESULT := "cas-test-result"
const KIND_DERIVE := "cas-derive"
const KIND_DERIVE_RESULT := "cas-derive-result"
const KIND_PLOT := "cas-plot"
const KIND_PLOT_RESULT := "cas-plot-result"
const KIND_PLOT3D := "cas-plot3d"
const KIND_PLOT3D_RESULT := "cas-plot3d-result"

const ENGINE_TAG := "csl-6547"   # bundled REDUCE build (see math_engine.gd)


## A block is one fenced region in the markdown.  `start` and `end` are line
## indices into the original `text.split("\n")` (start = opening fence,
## end = closing fence).
static func parse_blocks(text: String) -> Array:
	var blocks: Array = []
	var lines := text.split("\n")
	var i := 0
	while i < lines.size():
		var fence_kind := _fence_kind(lines[i])
		if fence_kind != "":
			var j := i + 1
			while j < lines.size() and not lines[j].strip_edges().begins_with("```"):
				j += 1
			var body_lines: PackedStringArray = lines.slice(i + 1, j)
			blocks.append({
				"kind": fence_kind,
				"start": i,
				"end": j,
				"body": "\n".join(body_lines),
			})
			i = j + 1
		else:
			i += 1
	return blocks


## Return the fence kind ("cas", "cas-result", ...) for an opening line,
## or "" if it isn't a known opening fence.
static func _fence_kind(line: String) -> String:
	var t := line.strip_edges()
	if not t.begins_with("```"):
		return ""
	var rest := t.substr(3).strip_edges()
	# Accept the known kinds exactly (no spaces / args yet).
	match rest:
		KIND_CAS, KIND_RESULT, KIND_TEST, KIND_TEST_RESULT, \
		KIND_DERIVE, KIND_DERIVE_RESULT, KIND_PLOT, KIND_PLOT_RESULT, \
		KIND_PLOT3D, KIND_PLOT3D_RESULT:
			return rest
		_:
			return ""


## Content hash for a `cas`-family block source. Includes engine tag so a
## kernel upgrade automatically invalidates cached results (P1, req #5).
static func source_hash(body: String, kind: String) -> String:
	var canonical := "%s|%s|%s" % [ENGINE_TAG, kind, body.strip_edges()]
	return canonical.sha1_text().substr(0, 12)


## Look at the `<!-- src-hash: ... -->` footer at the top of an existing
## result block and return the hash, or "" if not present.
static func extract_src_hash(result_body: String) -> String:
	var re := RegEx.new()
	re.compile("<!--\\s*src-hash:\\s*([a-f0-9]+)")
	var m := re.search(result_body)
	if m == null:
		return ""
	return m.get_string(1)


## Pair `cas` (or `cas-test`/`cas-derive`/`cas-plot`/`cas-plot3d`) blocks
## with the result block immediately following them, if any.
## Returns an array of {source: block, result: block_or_null}.
static func pair_blocks(blocks: Array) -> Array:
	const SRC_TO_RESULT := {
		KIND_CAS: KIND_RESULT,
		KIND_TEST: KIND_TEST_RESULT,
		KIND_DERIVE: KIND_DERIVE_RESULT,
		KIND_PLOT: KIND_PLOT_RESULT,
		KIND_PLOT3D: KIND_PLOT3D_RESULT,
	}
	var pairs: Array = []
	var i := 0
	while i < blocks.size():
		var b: Dictionary = blocks[i]
		var expected_result: String = SRC_TO_RESULT.get(b["kind"], "")
		if expected_result == "":
			i += 1
			continue
		var pair_result = null
		if i + 1 < blocks.size() and blocks[i + 1]["kind"] == expected_result:
			pair_result = blocks[i + 1]
			i += 2
		else:
			i += 1
		pairs.append({"source": b, "result": pair_result, "expected_result_kind": expected_result})
	return pairs


## Build a fresh result-block body, including provenance footer.
static func format_result_body(kind: String, src_hash: String, payload: String, ok: bool = true) -> String:
	var status_line := ""
	if kind == KIND_TEST_RESULT:
		status_line = ("PASS" if ok else "FAIL") + "\n"
	var footer := "<!-- src-hash: %s engine: %s -->" % [src_hash, ENGINE_TAG]
	return "%s%s%s\n%s" % [footer, "\n" if not payload.is_empty() else "", payload, ""]


## Rewrite the notebook text by replacing each paired result block (or
## inserting a new one) with the supplied new bodies.
## `replacements` is an Array of {pair, new_body, new_kind}.
## Returns the rewritten markdown text.
static func rewrite(text: String, replacements: Array) -> String:
	# Apply replacements bottom-up so line indices stay valid.
	var lines := text.split("\n")
	var sorted := replacements.duplicate()
	sorted.sort_custom(func(a, b): return _pair_start_line(a["pair"]) > _pair_start_line(b["pair"]))
	for r in sorted:
		var pair: Dictionary = r["pair"]
		var new_body: String = r["new_body"]
		var new_kind: String = r["new_kind"]
		var fence_open := "```%s" % new_kind
		var fence_close := "```"
		var new_block_lines: PackedStringArray = [fence_open]
		for bl in new_body.split("\n"):
			new_block_lines.append(bl)
		new_block_lines.append(fence_close)
		if pair["result"] != null:
			var rb: Dictionary = pair["result"]
			# Replace lines [rb.start .. rb.end] inclusive.
			var head: PackedStringArray = lines.slice(0, int(rb["start"]))
			var tail: PackedStringArray = lines.slice(int(rb["end"]) + 1)
			lines = head + new_block_lines + tail
		else:
			# Insert right after the source block's closing fence.
			var src: Dictionary = pair["source"]
			var head: PackedStringArray = lines.slice(0, int(src["end"]) + 1)
			var tail: PackedStringArray = lines.slice(int(src["end"]) + 1)
			lines = head + new_block_lines + tail
	return "\n".join(lines)


static func _pair_start_line(pair: Dictionary) -> int:
	var src: Dictionary = pair["source"]
	return int(src["start"])


## Strip the provenance footer line(s) and trailing blank from a result body,
## returning the visible payload only (useful for display / export).
static func payload_only(result_body: String) -> String:
	var out := PackedStringArray()
	for line in result_body.split("\n"):
		if line.strip_edges().begins_with("<!-- src-hash:"):
			continue
		out.append(line)
	return "\n".join(out).strip_edges()
