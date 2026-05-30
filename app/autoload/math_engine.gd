extends Node
## MathEngine — owns the long-lived symbolic computation back-end for the
## whole app and drives it over a stdin/stdout pipe.
##
## The back-end binary is bundled next to the exported executable, so the user
## launches one application and never sees or starts a separate engine.
##
## Correlation of replies to requests uses a SENTINEL marker printed by the
## back-end after each command — far more robust than parsing the interactive
## prompts.

signal result_ready(id: int, output: String, is_error: bool)
signal session_started()
signal session_failed(reason: String)

const SENTINEL_PREFIX := "<<<RDONE "
const SENTINEL_SUFFIX := ">>>"
const NO_SENTINEL := -2147483648   # distinct from any real id (incl. -1 warmup)

var _pid: int = -1
var _stdio: FileAccess
var _reader: Thread
var _running := false
var _next_id := 0
var _mutex := Mutex.new()
var _pending: Array[int] = []   # FIFO of ids still awaiting a result
var _ready_ok := false


func _ready() -> void:
	_start()


func is_ready() -> bool:
	return _ready_ok


## Resolve the bundled engine binary relative to the running executable, so the
## app is portable. Falls back to the dev location when run from the editor.
func _engine_exe_path() -> String:
	var exe_dir := OS.get_executable_path().get_base_dir()
	var candidates := [
		exe_dir.path_join("reduce/lib/csl/reduce.exe"),
		"i:/readtgodot/tools/reduce/lib/csl/reduce.exe",
	]
	for c in candidates:
		if FileAccess.file_exists(c):
			return c
	return candidates[0]


func _start() -> void:
	var exe := _engine_exe_path()
	if not FileAccess.file_exists(exe):
		_ready_ok = false
		session_failed.emit("Math engine binary not found at %s" % exe)
		return
	var info := OS.execute_with_pipe(exe, ["-w"])
	if info.is_empty():
		_ready_ok = false
		session_failed.emit("Failed to launch math engine process")
		return
	_pid = int(info.get("pid", -1))
	_stdio = info.get("stdio")
	_running = true
	_reader = Thread.new()
	_reader.start(_reader_loop)
	# Linear output + load the user-selected optional packages up front (state
	# persists for the whole session). A trailing sentinel (id -1) flushes any
	# package banner out of the reader buffer so it can't contaminate the
	# first result. Package list is read from user://packages.cfg via
	# PackageConfig (task 32); falls back to PackageConfig.DEFAULT_SELECTED
	# on first run / missing config.
	var pkg_load: String = PackageConfig.to_load_block(PackageConfig.load_selected())
	_stdio.store_string("off nat; off echo; %s\n" % pkg_load)
	_stdio.store_string('write "%s-1%s";%s' % [SENTINEL_PREFIX, SENTINEL_SUFFIX, "\n"])
	_stdio.flush()
	_ready_ok = true
	session_started.emit()


## Queue a command for evaluation. Returns an id; the answer arrives later via
## the result_ready signal carrying the same id (so the UI never blocks).
func evaluate(code: String) -> int:
	var id := _next_id
	_next_id += 1
	if not _ready_ok or _stdio == null:
		call_deferred("emit_signal", "result_ready", id, "session not started", true)
		return id
	var script := code.strip_edges()
	while script.ends_with(";") or script.ends_with("$"):
		script = script.substr(0, script.length() - 1)
	_mutex.lock()
	_pending.append(id)
	_mutex.unlock()
	_stdio.store_string(script + ";\n")
	_stdio.store_string('write "%s%d%s";%s' % [SENTINEL_PREFIX, id, SENTINEL_SUFFIX, "\n"])
	_stdio.flush()
	return id


## Restart the child engine process — used after the user changes the
## startup-package selection (task 31/32). The previous reader thread is
## torn down cleanly; `_start()` then spawns a fresh REDUCE with the new
## package set loaded.
func restart() -> void:
	_running = false
	if _stdio:
		_stdio.store_string("bye;\n")
		_stdio.flush()
	if _pid != -1:
		OS.kill(_pid)
		_pid = -1
	if _reader and _reader.is_started():
		_reader.wait_to_finish()
	_stdio = null
	_pending.clear()
	_next_id = 0
	_ready_ok = false
	_start()


## Deliberately clear engine state (variable bindings, modes) without
## restarting the whole application. Followed by a sentinel-flush so any
## echoed output from the reset commands ("clear$" etc.) gets emitted as
## its own ignored result instead of leaking into the next user request.
## (Bug fix — task 24.)
func reset_session() -> void:
	if _stdio == null:
		return
	# Note: `off latex` is intentionally omitted — the latex switch only
	# exists after `load_package rlfi`, which the app never loads on startup,
	# so sending `off latex` would error with "latex not defined as switch".
	_stdio.store_string("clear; off rounded;\n")
	_stdio.store_string('write "%s-2%s";%s' % [SENTINEL_PREFIX, SENTINEL_SUFFIX, "\n"])
	_stdio.flush()


func _reader_loop() -> void:
	var prompt_re := RegEx.new()
	prompt_re.compile("^\\s*\\d+:\\s*$")
	var buf := PackedStringArray()
	while _running:
		if _stdio == null or not _stdio.is_open():
			break
		var line := _stdio.get_line()
		if _stdio.get_error() != OK and line == "":
			break   # pipe closed / EOF
		var stripped := line.strip_edges()
		var sentinel_id := _match_sentinel(stripped)
		if sentinel_id != NO_SENTINEL:
			var text := "\n".join(buf).strip_edges()
			buf = PackedStringArray()
			var is_err := text.contains("*****")
			_mutex.lock()
			if not _pending.is_empty():
				_pending.remove_at(0)
			_mutex.unlock()
			call_deferred("emit_signal", "result_ready", sentinel_id, text, is_err)
		elif prompt_re.search(stripped) != null:
			pass   # drop interactive prompts
		elif stripped.begins_with("Reduce ("):
			pass   # drop the engine's startup banner
		elif stripped.begins_with("*****"):
			buf.append(stripped)   # keep genuine errors (5 stars)
		elif stripped.begins_with("***"):
			pass   # drop informational warnings, e.g. "*** depend y , x"
		elif stripped == "":
			pass   # drop blank lines
		else:
			buf.append(stripped)


func _match_sentinel(s: String) -> int:
	var i := s.find(SENTINEL_PREFIX)
	if i == -1:
		return NO_SENTINEL
	var rest := s.substr(i + SENTINEL_PREFIX.length())
	var j := rest.find(SENTINEL_SUFFIX)
	if j == -1:
		return NO_SENTINEL
	return rest.substr(0, j).to_int()


func _exit_tree() -> void:
	_running = false
	if _stdio:
		_stdio.store_string("bye;\n")
		_stdio.flush()
	if _pid != -1:
		OS.kill(_pid)
	if _reader and _reader.is_started():
		_reader.wait_to_finish()
