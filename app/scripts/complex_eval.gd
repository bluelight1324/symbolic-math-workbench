class_name ComplexEval
extends RefCounted
## Task 251.0 — a small complex-number expression evaluator for `cas-domain`
## (domain colouring). Godot's `Expression` is real-only, so this parses f(z) once
## into an AST and evaluates it per pixel with z a complex `Vector2(re, im)`.
##
## Supports: + - * / ^, unary minus, implicit multiplication (2z, 3i, z(z+1)),
## the variable `z`, constant `i`, `pi`, `e`, real literals, and the functions
## exp, log/ln, sqrt, sin, cos, tan, sinh, cosh, conj, abs, re, im.

var _tokens: PackedStringArray
var _pos: int
var _ast                       # parsed tree (nested Arrays), or null on error
var error: String = ""


func parse(src: String) -> bool:
	_tokens = _tokenize(src)
	_pos = 0
	error = ""
	if _tokens.is_empty():
		error = "empty expression"
		return false
	_ast = _parse_expr()
	if error == "" and _pos < _tokens.size():
		error = "unexpected '%s'" % _tokens[_pos]
	if error != "":
		_ast = null
		return false
	return _ast != null


func eval(z: Vector2) -> Vector2:
	if _ast == null:
		return Vector2.ZERO
	return _ev(_ast, z)


# --- tokeniser ---------------------------------------------------------------

func _tokenize(s: String) -> PackedStringArray:
	var out := PackedStringArray()
	var i := 0
	while i < s.length():
		var c := s[i]
		if c == " " or c == "\t" or c == "\n":
			i += 1
		elif "+-*/^()".find(c) != -1:
			out.append(c)
			i += 1
		elif _is_digit(c) or c == ".":
			var j := i
			while j < s.length() and (_is_digit(s[j]) or s[j] == "."):
				j += 1
			out.append(s.substr(i, j - i))
			i = j
		elif _is_alpha(c):
			var j := i
			while j < s.length() and (_is_alpha(s[j]) or _is_digit(s[j])):
				j += 1
			out.append(s.substr(i, j - i))
			i = j
		else:
			error = "bad character '%s'" % c
			i += 1
	return out


func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"


func _is_alpha(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"


func _is_number(t: String) -> bool:
	return t.length() > 0 and (_is_digit(t[0]) or t[0] == ".")


# --- recursive-descent parser ------------------------------------------------

func _peek() -> String:
	return _tokens[_pos] if _pos < _tokens.size() else ""


func _advance() -> String:
	var t := _peek()
	_pos += 1
	return t


func _starts_atom(t: String) -> bool:
	return t != "" and (_is_number(t) or t == "(" or _is_alpha(t[0]))


func _parse_expr():
	var node = _parse_term()
	while _peek() == "+" or _peek() == "-":
		var op := _advance()
		node = [op, node, _parse_term()]
	return node


func _parse_term():
	var node = _parse_factor()
	while true:
		var t := _peek()
		if t == "*" or t == "/":
			_advance()
			node = [t, node, _parse_factor()]
		elif _starts_atom(t):
			node = ["*", node, _parse_factor()]   # implicit multiplication
		else:
			break
	return node


func _parse_factor():
	var node = _parse_unary()
	if _peek() == "^":
		_advance()
		node = ["^", node, _parse_factor()]        # right-associative
	return node


func _parse_unary():
	if _peek() == "-":
		_advance()
		return ["neg", _parse_unary()]
	if _peek() == "+":
		_advance()
		return _parse_unary()
	return _parse_atom()


func _parse_atom():
	var t := _advance()
	if t == "":
		error = "unexpected end of expression"
		return null
	if t == "(":
		var node = _parse_expr()
		if _advance() != ")":
			error = "missing )"
		return node
	if _is_number(t):
		return ["num", Vector2(t.to_float(), 0.0)]
	if t == "i":
		return ["num", Vector2(0.0, 1.0)]
	if t == "z":
		return ["var"]
	if t == "pi":
		return ["num", Vector2(PI, 0.0)]
	if t == "e":
		return ["num", Vector2(exp(1.0), 0.0)]
	if _peek() == "(":                              # function call: name ( expr )
		_advance()
		var arg = _parse_expr()
		if _advance() != ")":
			error = "missing ) after %s" % t
		return ["fn", t, arg]
	error = "unknown symbol '%s'" % t
	return null


# --- evaluation --------------------------------------------------------------

func _ev(node, z: Vector2) -> Vector2:
	match node[0]:
		"num":
			var v: Vector2 = node[1]
			return v
		"var":
			return z
		"neg":
			return -_ev(node[1], z)
		"+":
			return _ev(node[1], z) + _ev(node[2], z)
		"-":
			return _ev(node[1], z) - _ev(node[2], z)
		"*":
			return _cmul(_ev(node[1], z), _ev(node[2], z))
		"/":
			return _cdiv(_ev(node[1], z), _ev(node[2], z))
		"^":
			return _cpow(_ev(node[1], z), _ev(node[2], z))
		"fn":
			return _cfn(node[1], _ev(node[2], z))
	return Vector2.ZERO


static func _cmul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)


static func _cdiv(a: Vector2, b: Vector2) -> Vector2:
	var d := b.x * b.x + b.y * b.y
	if d == 0.0:
		return Vector2(INF, INF)
	return Vector2((a.x * b.x + a.y * b.y) / d, (a.y * b.x - a.x * b.y) / d)


static func _cexp(a: Vector2) -> Vector2:
	var r := exp(a.x)
	return Vector2(r * cos(a.y), r * sin(a.y))


static func _clog(a: Vector2) -> Vector2:
	return Vector2(0.5 * log(a.x * a.x + a.y * a.y), atan2(a.y, a.x))


static func _cpow(a: Vector2, b: Vector2) -> Vector2:
	if a.x == 0.0 and a.y == 0.0:
		return Vector2.ZERO
	return _cexp(_cmul(b, _clog(a)))


static func _sinh(x: float) -> float:
	return 0.5 * (exp(x) - exp(-x))


static func _cosh(x: float) -> float:
	return 0.5 * (exp(x) + exp(-x))


func _cfn(name: String, a: Vector2) -> Vector2:
	match name:
		"exp":
			return _cexp(a)
		"log", "ln":
			return _clog(a)
		"sqrt":
			var h := _clog(a)
			return _cexp(Vector2(0.5 * h.x, 0.5 * h.y))
		"sin":
			return Vector2(sin(a.x) * _cosh(a.y), cos(a.x) * _sinh(a.y))
		"cos":
			return Vector2(cos(a.x) * _cosh(a.y), -sin(a.x) * _sinh(a.y))
		"tan":
			return _cdiv(
				Vector2(sin(a.x) * _cosh(a.y), cos(a.x) * _sinh(a.y)),
				Vector2(cos(a.x) * _cosh(a.y), -sin(a.x) * _sinh(a.y)))
		"sinh":
			return Vector2(_sinh(a.x) * cos(a.y), _cosh(a.x) * sin(a.y))
		"cosh":
			return Vector2(_cosh(a.x) * cos(a.y), _sinh(a.x) * sin(a.y))
		"conj":
			return Vector2(a.x, -a.y)
		"abs":
			return Vector2(a.length(), 0.0)
		"re":
			return Vector2(a.x, 0.0)
		"im":
			return Vector2(a.y, 0.0)
	error = "unknown function '%s'" % name
	return Vector2.ZERO
