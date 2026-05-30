class_name AdvancedLibrary
extends RefCounted
## A larger catalogue of preset problems — hundreds across many categories,
## displayed on a separate "Advanced" tab. (Task 26.)
##
## Items are generated parametrically where it keeps the source readable.
## Each entry is the same shape as `ProblemLibrary.ALL`:
##   { label: str, input: str (shown in the field), cmd: str (sent to engine) }


static func build() -> Array:
	return [
		{"name": "Expansion",          "items": _expansion()},
		{"name": "Factoring",          "items": _factoring()},
		{"name": "Differentiation",    "items": _diff_basic()},
		{"name": "Higher derivatives", "items": _diff_higher()},
		{"name": "Integration",        "items": _integration()},
		{"name": "Limits",             "items": _limits()},
		{"name": "Taylor series",      "items": _taylor()},
		{"name": "Trig identities",    "items": _trig_identities()},
		{"name": "First-order ODEs",   "items": _odes_first()},
		{"name": "Higher ODEs",        "items": _odes_higher()},
		{"name": "Matrices",           "items": _matrices()},
		{"name": "Number theory",      "items": _number_theory()},
		{"name": "Combinatorics",      "items": _combinatorics()},
	]


static func _item(label: String, cmd: String) -> Dictionary:
	return {"label": label, "input": cmd, "cmd": cmd}


# ----------------------------------------------------------------------------
# 1. Expansion  (~ 35 items)
# ----------------------------------------------------------------------------
static func _expansion() -> Array:
	var out := []
	for n in [2, 3, 4, 5, 6, 7, 8, 9, 10, 12]:
		out.append(_item("Expand (x+1)^%d" % n, "(x+1)^%d" % n))
	for n in [2, 3, 4, 5, 6, 7]:
		out.append(_item("Expand (x-1)^%d" % n, "(x-1)^%d" % n))
	for n in [2, 3, 4, 5, 6]:
		out.append(_item("Expand (x+y)^%d" % n, "(x+y)^%d" % n))
	for n in [3, 4, 5, 6, 7]:
		out.append(_item("Expand (1+x+x^2)^%d" % n, "(1+x+x^2)^%d" % n))
	for n in [2, 3, 4, 5]:
		out.append(_item("Expand (a+b+c)^%d" % n, "(a+b+c)^%d" % n))
	out.append(_item("Expand (x+y)(x-y)", "(x+y)*(x-y)"))
	out.append(_item("Expand (x^2+x+1)(x^2-x+1)", "(x^2+x+1)*(x^2-x+1)"))
	return out


# ----------------------------------------------------------------------------
# 2. Factoring  (~ 30 items)
# ----------------------------------------------------------------------------
static func _factoring() -> Array:
	var out := []
	for n in [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15]:
		out.append(_item("Factor x^%d - 1" % n, "factorize(x^%d - 1)" % n))
	for n in [3, 4, 5, 6, 7, 8]:
		out.append(_item("Factor x^%d + 1" % n, "factorize(x^%d + 1)" % n))
	for c in [4, 9, 16, 25, 27, 64]:
		out.append(_item("Factor x^2 - %d" % c, "factorize(x^2 - %d)" % c))
	out += [
		_item("Factor x^4 - y^4",            "factorize(x^4 - y^4)"),
		_item("Factor x^3 + y^3",            "factorize(x^3 + y^3)"),
		_item("Factor x^3 - y^3",            "factorize(x^3 - y^3)"),
		_item("Factor x^4 + 4*y^4",          "factorize(x^4 + 4*y^4)"),
		_item("Factor x^2 - 5*x + 6",        "factorize(x^2 - 5*x + 6)"),
		_item("Factor 2*x^2 + 7*x + 3",      "factorize(2*x^2 + 7*x + 3)"),
	]
	return out


# ----------------------------------------------------------------------------
# 3. Differentiation — basic  (~ 30 items)
# ----------------------------------------------------------------------------
static func _diff_basic() -> Array:
	var out := []
	for f in ["sin(x)", "cos(x)", "tan(x)", "exp(x)", "log(x)",
			 "asin(x)", "acos(x)", "atan(x)",
			 "sinh(x)", "cosh(x)", "tanh(x)"]:
		out.append(_item("d/dx %s" % f, "df(%s, x)" % f))
	for a in [
		"sin(x)*cos(x)", "x*exp(x)", "x*log(x)",
		"sin(x)/x", "log(x)/x", "exp(x)*sin(x)",
		"atan(x)*log(x)", "x^x", "log(log(x))",
		"sin(x^2)", "cos(exp(x))", "exp(-x^2)",
		"sqrt(1+x^2)", "1/(1+x^2)", "(x+1)/(x-1)",
		"x*sqrt(1-x^2)", "sin(x)^cos(x)", "tan(sin(x))",
		"x/(x^2+1)", "log(x^2+1)",
	]:
		out.append(_item("d/dx %s" % a, "df(%s, x)" % a))
	return out


# ----------------------------------------------------------------------------
# 4. Higher derivatives  (~ 20 items)
# ----------------------------------------------------------------------------
static func _diff_higher() -> Array:
	var out := []
	for n in [2, 3, 4, 5]:
		out.append(_item("d^%d/dx^%d sin(x)" % [n, n], "df(sin(x), x, %d)" % n))
		out.append(_item("d^%d/dx^%d exp(x)" % [n, n], "df(exp(x), x, %d)" % n))
		out.append(_item("d^%d/dx^%d log(x)" % [n, n], "df(log(x), x, %d)" % n))
		out.append(_item("d^%d/dx^%d sin(x)*x" % [n, n], "df(sin(x)*x, x, %d)" % n))
		out.append(_item("d^%d/dx^%d exp(x)*sin(x)" % [n, n], "df(exp(x)*sin(x), x, %d)" % n))
	return out


# ----------------------------------------------------------------------------
# 5. Integration  (~ 35 items)
# ----------------------------------------------------------------------------
static func _integration() -> Array:
	return [
		_item("∫ sin(x) dx",                "int(sin(x), x)"),
		_item("∫ cos(x) dx",                "int(cos(x), x)"),
		_item("∫ tan(x) dx",                "int(tan(x), x)"),
		_item("∫ sin(x)^2 dx",              "int(sin(x)^2, x)"),
		_item("∫ cos(x)^2 dx",              "int(cos(x)^2, x)"),
		_item("∫ sin(x)*cos(x) dx",         "int(sin(x)*cos(x), x)"),
		_item("∫ 1/(x^2+1) dx",             "int(1/(x^2+1), x)"),
		_item("∫ 1/(x^2-1) dx",             "int(1/(x^2-1), x)"),
		_item("∫ 1/(x^2+a^2) dx",           "int(1/(x^2+a^2), x)"),
		_item("∫ 1/(x^3+1) dx",             "int(1/(x^3+1), x)"),
		_item("∫ 1/(x^4+1) dx",             "int(1/(x^4+1), x)"),
		_item("∫ 1/sqrt(1-x^2) dx",         "int(1/sqrt(1-x^2), x)"),
		_item("∫ 1/sqrt(1+x^2) dx",         "int(1/sqrt(1+x^2), x)"),
		_item("∫ sqrt(1-x^2) dx",           "int(sqrt(1-x^2), x)"),
		_item("∫ sqrt(1+x^2) dx",           "int(sqrt(1+x^2), x)"),
		_item("∫ x*exp(x) dx",              "int(x*exp(x), x)"),
		_item("∫ x*sin(x) dx",              "int(x*sin(x), x)"),
		_item("∫ x*cos(x) dx",              "int(x*cos(x), x)"),
		_item("∫ x^2*exp(x) dx",            "int(x^2*exp(x), x)"),
		_item("∫ log(x) dx",                "int(log(x), x)"),
		_item("∫ x*log(x) dx",              "int(x*log(x), x)"),
		_item("∫ log(x)^2 dx",              "int(log(x)^2, x)"),
		_item("∫ log(x)/x dx",              "int(log(x)/x, x)"),
		_item("∫ exp(x)*sin(x) dx",         "int(exp(x)*sin(x), x)"),
		_item("∫ exp(x)*cos(x) dx",         "int(exp(x)*cos(x), x)"),
		_item("∫ sin(x)/x partial",         "int(sin(x)/x, x)"),
		_item("∫ atan(x) dx",               "int(atan(x), x)"),
		_item("∫ asin(x) dx",               "int(asin(x), x)"),
		_item("∫ acos(x) dx",               "int(acos(x), x)"),
		_item("∫ x/(x^2+1) dx",             "int(x/(x^2+1), x)"),
		_item("∫ 1/(x*(x-1)*(x-2)) dx",     "int(1/(x*(x-1)*(x-2)), x)"),
		_item("∫ exp(-x^2) dx",             "int(exp(-x^2), x)"),
		_item("∫ exp(x)/x dx",              "int(exp(x)/x, x)"),
		_item("∫ 1/(sin(x)+cos(x)) dx",     "int(1/(sin(x)+cos(x)), x)"),
		_item("∫ sec(x)^2 dx",              "int(sec(x)^2, x)"),
	]


# ----------------------------------------------------------------------------
# 6. Limits  (~ 20 items)
# ----------------------------------------------------------------------------
static func _limits() -> Array:
	return [
		_item("lim sin(x)/x, x→0",                "limit(sin(x)/x, x, 0)"),
		_item("lim (1-cos(x))/x^2, x→0",           "limit((1-cos(x))/x^2, x, 0)"),
		_item("lim (1+1/n)^n, n→∞",                "limit((1+1/n)^n, n, infinity)"),
		_item("lim (1+x)^(1/x), x→0",              "limit((1+x)^(1/x), x, 0)"),
		_item("lim x*sin(1/x), x→∞",               "limit(x*sin(1/x), x, infinity)"),
		_item("lim log(x)/x, x→∞",                 "limit(log(x)/x, x, infinity)"),
		_item("lim x/log(x), x→∞",                 "limit(x/log(x), x, infinity)"),
		_item("lim exp(x)/x^n, x→∞ (n=3)",         "limit(exp(x)/x^3, x, infinity)"),
		_item("lim (exp(x)-1)/x, x→0",             "limit((exp(x)-1)/x, x, 0)"),
		_item("lim (sin(2*x))/x, x→0",             "limit(sin(2*x)/x, x, 0)"),
		_item("lim (tan(x))/x, x→0",               "limit(tan(x)/x, x, 0)"),
		_item("lim (log(1+x))/x, x→0",             "limit(log(1+x)/x, x, 0)"),
		_item("lim (a^x - 1)/x, x→0",              "limit((a^x - 1)/x, x, 0)"),
		_item("lim ((1+1/x)^x - e), x→∞",          "limit((1+1/x)^x - e, x, infinity)"),
		_item("lim sqrt(x+1)-sqrt(x), x→∞",        "limit(sqrt(x+1)-sqrt(x), x, infinity)"),
		_item("lim x*(sqrt(1+1/x)-1), x→∞",        "limit(x*(sqrt(1+1/x)-1), x, infinity)"),
		_item("lim (1-cos(x))/sin(x)^2, x→0",      "limit((1-cos(x))/sin(x)^2, x, 0)"),
		_item("lim atan(x), x→∞",                  "limit(atan(x), x, infinity)"),
		_item("lim x^(1/x), x→∞",                  "limit(x^(1/x), x, infinity)"),
		_item("lim (e^x - e^(-x))/x, x→0",         "limit((exp(x)-exp(-x))/x, x, 0)"),
	]


# ----------------------------------------------------------------------------
# 7. Taylor series  (~ 25 items)
# ----------------------------------------------------------------------------
static func _taylor() -> Array:
	var out := []
	for fp in [
		["exp(x)", "exp"], ["sin(x)", "sin"], ["cos(x)", "cos"],
		["log(1+x)", "log(1+x)"], ["atan(x)", "atan"], ["asin(x)", "asin"],
		["1/(1-x)", "1/(1-x)"], ["sqrt(1+x)", "√(1+x)"], ["sin(x)*cos(x)", "sinx·cosx"],
		["exp(x)*sin(x)", "eˣ·sinx"], ["log(cos(x))", "log(cos x)"],
		["tan(x)", "tan"],
	]:
		var f: String = fp[0]
		var n: String = fp[1]
		for order in [5, 7, 10]:
			out.append(_item(
				"Taylor %s, order %d" % [n, order],
				"taylor(%s, x, 0, %d)" % [f, order]))
	return out


# ----------------------------------------------------------------------------
# 8. Trig identities  (~ 25 items)
# ----------------------------------------------------------------------------
static func _trig_identities() -> Array:
	return [
		_item("sin^2 + cos^2",                  "trigsimp(sin(x)^2 + cos(x)^2)"),
		_item("1 - cos(2x)/2 = sin^2",          "trigsimp((1-cos(2*x))/2)"),
		_item("Expand sin(x+y)",                "trigsimp(sin(x+y), expand)"),
		_item("Expand cos(x+y)",                "trigsimp(cos(x+y), expand)"),
		_item("Expand tan(x+y)",                "trigsimp(tan(x+y), expand)"),
		_item("Expand sin(2x)",                 "trigsimp(sin(2*x), expand)"),
		_item("Expand cos(2x)",                 "trigsimp(cos(2*x), expand)"),
		_item("Expand sin(3x)",                 "trigsimp(sin(3*x), expand)"),
		_item("Expand cos(3x)",                 "trigsimp(cos(3*x), expand)"),
		_item("Expand sin(4x)",                 "trigsimp(sin(4*x), expand)"),
		_item("Combine sin(x)*cos(y)",          "trigsimp(sin(x)*cos(y), combine)"),
		_item("Combine sin(x)*sin(y)",          "trigsimp(sin(x)*sin(y), combine)"),
		_item("Combine cos(x)*cos(y)",          "trigsimp(cos(x)*cos(y), combine)"),
		_item("sin(x)*cos(x) → ½sin(2x)",       "trigsimp(sin(x)*cos(x), combine)"),
		_item("sin(x)+sin(y) sum→product",      "trigsimp(sin(x)+sin(y), combine)"),
		_item("cos(x)+cos(y) sum→product",      "trigsimp(cos(x)+cos(y), combine)"),
		_item("Simplify tan in sin/cos",        "trigsimp(tan(x)*sin(x))"),
		_item("Half-angle sin(x/2)^2",          "trigsimp(sin(x/2)^2)"),
		_item("Identity sec^2 = 1+tan^2",       "trigsimp(sec(x)^2 - 1 - tan(x)^2)"),
		_item("Identity csc^2 = 1+cot^2",       "trigsimp(csc(x)^2 - 1 - cot(x)^2)"),
		_item("Solve sin(x) = 1/2",             "solve(sin(x) - 1/2, x)"),
		_item("Solve cos(x) = 1/2",             "solve(cos(x) - 1/2, x)"),
		_item("Solve sin(x) = cos(x)",          "solve(sin(x) - cos(x), x)"),
		_item("Solve tan(x) = 1",               "solve(tan(x) - 1, x)"),
		_item("Solve sin(2x) = sin(x)",         "solve(sin(2*x) - sin(x), x)"),
	]


# ----------------------------------------------------------------------------
# 9. First-order ODEs  (~ 20 items)
# ----------------------------------------------------------------------------
static func _odes_first() -> Array:
	return [
		_item("y' = y",                           "odesolve(df(y,x) = y, y, x)"),
		_item("y' = -y",                          "odesolve(df(y,x) = -y, y, x)"),
		_item("y' = x",                           "odesolve(df(y,x) = x, y, x)"),
		_item("y' = x*y",                         "odesolve(df(y,x) = x*y, y, x)"),
		_item("y' = x + y",                       "odesolve(df(y,x) = x + y, y, x)"),
		_item("y' - y = x",                       "odesolve(df(y,x) - y = x, y, x)"),
		_item("y' - y = exp(x)",                  "odesolve(df(y,x) - y = exp(x), y, x)"),
		_item("y' + 2*y = sin(x)",                "odesolve(df(y,x) + 2*y = sin(x), y, x)"),
		_item("x*y' + y = x^2",                   "odesolve(x*df(y,x) + y = x^2, y, x)"),
		_item("x*y' = y + x^2",                   "odesolve(x*df(y,x) = y + x^2, y, x)"),
		_item("y' = (x+y)/(x-y)",                 "odesolve(df(y,x) = (x+y)/(x-y), y, x)"),
		_item("y' = y/x",                         "odesolve(df(y,x) = y/x, y, x)"),
		_item("y' = exp(x-y)",                    "odesolve(df(y,x) = exp(x-y), y, x)"),
		_item("y' = sin(x)*cos(y)",               "odesolve(df(y,x) = sin(x)*cos(y), y, x)"),
		_item("y' + y*tan(x) = 0",                "odesolve(df(y,x) + y*tan(x) = 0, y, x)"),
		_item("(1+x^2)*y' = 1",                   "odesolve((1+x^2)*df(y,x) = 1, y, x)"),
		_item("y' = y^2",                         "odesolve(df(y,x) = y^2, y, x)"),
		_item("y' = -y/x^2",                      "odesolve(df(y,x) = -y/x^2, y, x)"),
		_item("y' = x^2*y",                       "odesolve(df(y,x) = x^2*y, y, x)"),
		_item("y' = x*exp(y)",                    "odesolve(df(y,x) = x*exp(y), y, x)"),
	]


# ----------------------------------------------------------------------------
# 10. Higher-order ODEs  (~ 15 items)
# ----------------------------------------------------------------------------
static func _odes_higher() -> Array:
	return [
		_item("y'' + y = 0",                       "odesolve(df(y,x,2) + y = 0, y, x)"),
		_item("y'' - y = 0",                       "odesolve(df(y,x,2) - y = 0, y, x)"),
		_item("y'' - 3*y' + 2*y = 0",              "odesolve(df(y,x,2) - 3*df(y,x) + 2*y = 0, y, x)"),
		_item("y'' + 4*y' + 4*y = 0",              "odesolve(df(y,x,2) + 4*df(y,x) + 4*y = 0, y, x)"),
		_item("y'' + 2*y' + 5*y = 0",              "odesolve(df(y,x,2) + 2*df(y,x) + 5*y = 0, y, x)"),
		_item("y'' + y = sin(x) (resonance)",      "odesolve(df(y,x,2) + y = sin(x), y, x)"),
		_item("y'' + y = cos(x)",                  "odesolve(df(y,x,2) + y = cos(x), y, x)"),
		_item("y'' - y = exp(x)",                  "odesolve(df(y,x,2) - y = exp(x), y, x)"),
		_item("y'' + 4*y = sin(x)",                "odesolve(df(y,x,2) + 4*y = sin(x), y, x)"),
		_item("y'' - y' = x",                      "odesolve(df(y,x,2) - df(y,x) = x, y, x)"),
		_item("y'' + y = x*sin(x)",                "odesolve(df(y,x,2) + y = x*sin(x), y, x)"),
		_item("y''' - y = 0",                      "odesolve(df(y,x,3) - y = 0, y, x)"),
		_item("y''' + y' = 0",                     "odesolve(df(y,x,3) + df(y,x) = 0, y, x)"),
		_item("y'''' + y = 0",                     "odesolve(df(y,x,4) + y = 0, y, x)"),
		_item("y'' + 2*y' + y = x*exp(-x)",        "odesolve(df(y,x,2) + 2*df(y,x) + y = x*exp(-x), y, x)"),
	]


# ----------------------------------------------------------------------------
# 11. Matrices  (~ 25 items)
# ----------------------------------------------------------------------------
static func _matrices() -> Array:
	return [
		_item("det mat((1,2),(3,4))",                       "det mat((1,2),(3,4))"),
		_item("det mat((2,1),(1,2))",                       "det mat((2,1),(1,2))"),
		_item("det mat((1,2,3),(0,1,4),(5,6,0))",           "det mat((1,2,3),(0,1,4),(5,6,0))"),
		_item("det mat((1,1,1),(1,2,3),(1,4,9))",           "det mat((1,1,1),(1,2,3),(1,4,9))"),
		_item("det mat((a,b),(c,d))",                       "det mat((a,b),(c,d))"),
		_item("trace mat((1,2,3),(4,5,6),(7,8,9))",          "trace mat((1,2,3),(4,5,6),(7,8,9))"),
		_item("trace mat((a,b,c),(d,e,f),(g,h,i))",          "trace mat((a,b,c),(d,e,f),(g,h,i))"),
		_item("Inverse mat((1,2),(3,4))",                    "mat((1,2),(3,4))^(-1)"),
		_item("Inverse mat((2,1),(1,2))",                    "mat((2,1),(1,2))^(-1)"),
		_item("Inverse mat((1,2,3),(0,1,4),(5,6,0))",        "mat((1,2,3),(0,1,4),(5,6,0))^(-1)"),
		_item("Inverse mat((a,b),(c,d))",                    "mat((a,b),(c,d))^(-1)"),
		_item("M^2 of mat((1,2),(3,4))",                     "mat((1,2),(3,4))^2"),
		_item("M^3 of mat((1,2),(3,4))",                     "mat((1,2),(3,4))^3"),
		_item("M^4 of mat((0,1),(-1,0))",                    "mat((0,1),(-1,0))^4"),
		_item("Product 2×2 · 2×2",                            "mat((1,2),(3,4)) * mat((5,6),(7,8))"),
		_item("Product 3×3 · 3×3",                            "mat((1,2,3),(4,5,6),(7,8,10)) * mat((1,0,0),(0,1,0),(0,0,1))"),
		_item("Transpose mat((1,2,3),(4,5,6))",              "tp mat((1,2,3),(4,5,6))"),
		_item("Transpose mat((a,b),(c,d))",                  "tp mat((a,b),(c,d))"),
		_item("Solve M·v = b (2×2)",                         "mat((1,2),(3,4))^(-1) * mat((5),(11))"),
		_item("(M + M^T)/2 — symm part",                     "(mat((1,2),(3,4)) + tp mat((1,2),(3,4)))/2"),
		_item("(M − M^T)/2 — antisymm",                      "(mat((1,2),(3,4)) - tp mat((1,2),(3,4)))/2"),
		_item("det of rotation by π/3",                       "det mat((cos(pi/3),-sin(pi/3)),(sin(pi/3),cos(pi/3)))"),
		_item("Rotation × rotation (compose)",                "mat((cos(a),-sin(a)),(sin(a),cos(a))) * mat((cos(b),-sin(b)),(sin(b),cos(b)))"),
		_item("Outer product (column · row)",                 "mat((a),(b),(c)) * mat((x,y,z))"),
		_item("Diagonal raised to 5th",                       "mat((2,0,0),(0,3,0),(0,0,5))^5"),
	]


# ----------------------------------------------------------------------------
# 12. Number theory  (~ 25 items)
# ----------------------------------------------------------------------------
static func _number_theory() -> Array:
	var out := []
	for pair in [[60, 84], [120, 144], [7, 11], [1071, 462], [123456, 987654],
				 [2^10, 3^7], [101, 103]]:
		var a: int = pair[0]
		var b: int = pair[1]
		out.append(_item("gcd(%d, %d)" % [a, b], "gcd(%d, %d)" % [a, b]))
		out.append(_item("lcm(%d, %d)" % [a, b], "lcm(%d, %d)" % [a, b]))
	for n in [60, 360, 720, 1024, 65536, 999999, 123456789, 1000000007]:
		out.append(_item("Factorize %d" % n, "factorize %d" % n))
	for n in [10, 20, 30, 50, 80, 100, 200]:
		out.append(_item("%d!" % n, "factorial(%d)" % n))
	return out


# ----------------------------------------------------------------------------
# 13. Combinatorics  (~ 15 items)
# ----------------------------------------------------------------------------
static func _combinatorics() -> Array:
	var out := []
	for pair in [[5, 2], [10, 3], [10, 5], [20, 10], [30, 15],
				 [50, 25], [100, 50], [13, 5], [52, 5]]:
		var n: int = pair[0]
		var k: int = pair[1]
		out.append(_item("C(%d, %d)" % [n, k], "binomial(%d, %d)" % [n, k]))
	out += [
		_item("Sum of squares 1..n",      "(n*(n+1)*(2*n+1))/6"),
		_item("Sum of cubes 1..n",        "(n*(n+1)/2)^2"),
		_item("Fibonacci-style ratio test","limit(fib(n+1)/fib(n), n, infinity)"),
		_item("Binomial expansion theorem","(x+y)^4"),
		_item("Multinomial trinomial^3",   "(a+b+c)^3"),
		_item("Pascal row 8",              "for k:=0:8 collect binomial(8,k)"),
	]
	return out
