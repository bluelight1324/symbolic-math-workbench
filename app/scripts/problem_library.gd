class_name ProblemLibrary
extends RefCounted
## A large catalogue of preset symbolic-math problems, grouped into categories
## for the menu bar. Each item has:
##   label : what the user sees in the menu
##   input : text dropped into the input field (so the user has a clean record)
##   cmd   : the actual engine command to evaluate
##   kind  : (optional) "plot" routes through the plot pipeline; default "raw"

const ALL := [
	{
		"name": "Algebra",
		"items": [
			{"label": "Expand (x+1)^5",                "input": "(x+1)^5",                "cmd": "(x+1)^5"},
			{"label": "Expand (x+y)^4",                "input": "(x+y)^4",                "cmd": "(x+y)^4"},
			{"label": "Expand (1+x+x^2)^3",            "input": "(1+x+x^2)^3",            "cmd": "(1+x+x^2)^3"},
			{"label": "Factor x^6 - 1",                "input": "factorize(x^6 - 1)",     "cmd": "factorize(x^6 - 1)"},
			{"label": "Factor x^4 - 16",               "input": "factorize(x^4 - 16)",    "cmd": "factorize(x^4 - 16)"},
			{"label": "Factor x^3 - y^3",              "input": "factorize(x^3 - y^3)",   "cmd": "factorize(x^3 - y^3)"},
			{"label": "Simplify (a^2-b^2)/(a-b)",      "input": "(a^2-b^2)/(a-b)",        "cmd": "(a^2-b^2)/(a-b)"},
			{"label": "Simplify (x^2-1)/(x-1)",        "input": "(x^2-1)/(x-1)",          "cmd": "(x^2-1)/(x-1)"},
			{"label": "Partial fractions 1/((x-1)(x-2))", "input": "pf(1/((x-1)*(x-2)), x)", "cmd": "pf(1/((x-1)*(x-2)), x)"},
			{"label": "Partial fractions 1/((x-1)(x-2)(x-3))", "input": "pf(1/((x-1)*(x-2)*(x-3)), x)", "cmd": "pf(1/((x-1)*(x-2)*(x-3)), x)"},
			{"label": "GCD x^2-1, x^2+2x+1",           "input": "gcd(x^2-1, x^2+2*x+1)",  "cmd": "gcd(x^2-1, x^2+2*x+1)"},
			{"label": "LCM x^2-1, x^2+2x+1",           "input": "lcm(x^2-1, x^2+2*x+1)",  "cmd": "lcm(x^2-1, x^2+2*x+1)"},
		],
	},
	{
		"name": "Calculus",
		"items": [
			{"label": "d/dx sin(x)*cos(x)",            "input": "df(sin(x)*cos(x), x)",    "cmd": "df(sin(x)*cos(x), x)"},
			{"label": "d/dx x*e^x",                    "input": "df(x*exp(x), x)",         "cmd": "df(x*exp(x), x)"},
			{"label": "d/dx x^x",                      "input": "df(x^x, x)",              "cmd": "df(x^x, x)"},
			{"label": "d/dx log(x)/x",                 "input": "df(log(x)/x, x)",         "cmd": "df(log(x)/x, x)"},
			{"label": "d/dx atan(x)",                  "input": "df(atan(x), x)",          "cmd": "df(atan(x), x)"},
			{"label": "3rd derivative sin(x)*e^x",     "input": "df(sin(x)*exp(x), x, 3)", "cmd": "df(sin(x)*exp(x), x, 3)"},
			{"label": "∫ 1/(x^2+1) dx",                "input": "int(1/(x^2+1), x)",       "cmd": "int(1/(x^2+1), x)"},
			{"label": "∫ sin(x)^2 dx",                 "input": "int(sin(x)^2, x)",        "cmd": "int(sin(x)^2, x)"},
			{"label": "∫ x*e^x dx",                    "input": "int(x*exp(x), x)",        "cmd": "int(x*exp(x), x)"},
			{"label": "∫ 1/sqrt(1-x^2) dx",            "input": "int(1/sqrt(1-x^2), x)",   "cmd": "int(1/sqrt(1-x^2), x)"},
			{"label": "∫ log(x) dx",                   "input": "int(log(x), x)",          "cmd": "int(log(x), x)"},
			{"label": "∫ x/(x^2+1) dx",                "input": "int(x/(x^2+1), x)",       "cmd": "int(x/(x^2+1), x)"},
			{"label": "∫ 1/(x*(x-1)*(x-2)) dx",        "input": "int(1/(x*(x-1)*(x-2)), x)", "cmd": "int(1/(x*(x-1)*(x-2)), x)"},
		],
	},
	{
		"name": "Equations",
		"items": [
			{"label": "Solve x^2 - 5x + 6 = 0",        "input": "solve(x^2 - 5*x + 6, x)",  "cmd": "solve(x^2 - 5*x + 6, x)"},
			{"label": "Solve x^3 - 1 = 0",             "input": "solve(x^3 - 1, x)",        "cmd": "solve(x^3 - 1, x)"},
			{"label": "Solve x^2 + x + 1 = 0",         "input": "solve(x^2 + x + 1, x)",    "cmd": "solve(x^2 + x + 1, x)"},
			{"label": "Solve x^4 - 1 = 0",             "input": "solve(x^4 - 1, x)",        "cmd": "solve(x^4 - 1, x)"},
			{"label": "Solve quintic x^5 - x - 1",     "input": "solve(x^5 - x - 1, x)",    "cmd": "solve(x^5 - x - 1, x)"},
			{"label": "System: x+y=3, x-y=1",          "input": "solve({x+y=3, x-y=1}, {x,y})", "cmd": "solve({x+y=3, x-y=1}, {x,y})"},
			{"label": "System: x^2+y=5, x+y=3",        "input": "solve({x^2+y=5, x+y=3}, {x,y})", "cmd": "solve({x^2+y=5, x+y=3}, {x,y})"},
			{"label": "Solve sin(x) = 1/2",            "input": "solve(sin(x) - 1/2, x)",   "cmd": "solve(sin(x) - 1/2, x)"},
		],
	},
	{
		"name": "ODEs",
		"items": [
			{"label": "y' = y",                        "input": "odesolve(df(y,x) = y, y, x)",          "cmd": "odesolve(df(y,x) = y, y, x)"},
			{"label": "y' = x*y",                      "input": "odesolve(df(y,x) = x*y, y, x)",        "cmd": "odesolve(df(y,x) = x*y, y, x)"},
			{"label": "y' - y = x",                    "input": "odesolve(df(y,x) - y = x, y, x)",      "cmd": "odesolve(df(y,x) - y = x, y, x)"},
			{"label": "x*y' + y = x^2",                "input": "odesolve(x*df(y,x) + y = x^2, y, x)",  "cmd": "odesolve(x*df(y,x) + y = x^2, y, x)"},
			{"label": "y'' + y = 0  (SHM)",            "input": "odesolve(df(y,x,2) + y = 0, y, x)",    "cmd": "odesolve(df(y,x,2) + y = 0, y, x)"},
			{"label": "y'' - y = 0",                   "input": "odesolve(df(y,x,2) - y = 0, y, x)",    "cmd": "odesolve(df(y,x,2) - y = 0, y, x)"},
			{"label": "y'' - 3y' + 2y = 0",            "input": "odesolve(df(y,x,2) - 3*df(y,x) + 2*y = 0, y, x)", "cmd": "odesolve(df(y,x,2) - 3*df(y,x) + 2*y = 0, y, x)"},
			{"label": "y'' + y = sin(x) (forced)",     "input": "odesolve(df(y,x,2) + y = sin(x), y, x)", "cmd": "odesolve(df(y,x,2) + y = sin(x), y, x)"},
		],
	},
	{
		"name": "Matrices",
		"items": [
			{"label": "Matrix product 2×2 · 2×2",      "input": "mat((1,2),(3,4)) * mat((5,6),(7,8))",  "cmd": "mat((1,2),(3,4)) * mat((5,6),(7,8))"},
			{"label": "Determinant of 3×3",            "input": "det mat((1,2,3),(0,1,4),(5,6,0))",     "cmd": "det mat((1,2,3),(0,1,4),(5,6,0))"},
			{"label": "Inverse of 2×2",                "input": "mat((1,2),(3,4))^(-1)",                "cmd": "mat((1,2),(3,4))^(-1)"},
			{"label": "Inverse of 3×3",                "input": "mat((1,2,3),(0,1,4),(5,6,0))^(-1)",    "cmd": "mat((1,2,3),(0,1,4),(5,6,0))^(-1)"},
			{"label": "Trace of 3×3",                  "input": "trace mat((1,2,3),(4,5,6),(7,8,9))",   "cmd": "trace mat((1,2,3),(4,5,6),(7,8,9))"},
			{"label": "Matrix squared",                "input": "mat((1,2),(3,4))^2",                   "cmd": "mat((1,2),(3,4))^2"},
		],
	},
	{
		"name": "Series",
		"items": [
			{"label": "Taylor exp(x) at 0, order 5",   "input": "taylor(exp(x), x, 0, 5)",      "cmd": "taylor(exp(x), x, 0, 5)"},
			{"label": "Taylor sin(x) at 0, order 7",   "input": "taylor(sin(x), x, 0, 7)",      "cmd": "taylor(sin(x), x, 0, 7)"},
			{"label": "Taylor log(1+x) at 0, order 6", "input": "taylor(log(1+x), x, 0, 6)",    "cmd": "taylor(log(1+x), x, 0, 6)"},
			{"label": "Taylor 1/(1-x) at 0, order 6",  "input": "taylor(1/(1-x), x, 0, 6)",     "cmd": "taylor(1/(1-x), x, 0, 6)"},
			{"label": "limit sin(x)/x → 0",            "input": "limit(sin(x)/x, x, 0)",        "cmd": "limit(sin(x)/x, x, 0)"},
			{"label": "limit (1+1/n)^n → ∞",           "input": "limit((1+1/n)^n, n, infinity)", "cmd": "limit((1+1/n)^n, n, infinity)"},
			{"label": "limit (1-cos x)/x^2 → 0",       "input": "limit((1-cos(x))/x^2, x, 0)",  "cmd": "limit((1-cos(x))/x^2, x, 0)"},
		],
	},
	{
		"name": "Trig",
		"items": [
			{"label": "Simplify sin²+cos² (trigsimp)", "input": "trigsimp(sin(x)^2 + cos(x)^2)", "cmd": "trigsimp(sin(x)^2 + cos(x)^2)"},
			{"label": "Expand sin(x+y)",               "input": "trigsimp(sin(x+y), expand)",    "cmd": "trigsimp(sin(x+y), expand)"},
			{"label": "Expand cos(2x)",                "input": "trigsimp(cos(2*x), expand)",    "cmd": "trigsimp(cos(2*x), expand)"},
			{"label": "Combine sin(x)cos(y)",          "input": "trigsimp(sin(x)*cos(y), combine)", "cmd": "trigsimp(sin(x)*cos(y), combine)"},
			{"label": "d/dx tan(x)",                   "input": "df(tan(x), x)",                 "cmd": "df(tan(x), x)"},
		],
	},
	{
		"name": "Numbers",
		"items": [
			{"label": "gcd(60, 84)",                   "input": "gcd(60, 84)",       "cmd": "gcd(60, 84)"},
			{"label": "Factorize 360",                 "input": "factorize 360",     "cmd": "factorize 360"},
			{"label": "Factorize 123456789",           "input": "factorize 123456789", "cmd": "factorize 123456789"},
			{"label": "binomial(10, 3)",               "input": "binomial(10, 3)",   "cmd": "binomial(10, 3)"},
			{"label": "binomial(20, 10)",              "input": "binomial(20, 10)",  "cmd": "binomial(20, 10)"},
			{"label": "100!",                          "input": "factorial(100)",    "cmd": "factorial(100)"},
		],
	},
	{
		"name": "Plots",
		"items": [
			{"label": "Plot sin(x)",          "input": "sin(x)",          "cmd": "",  "kind": "plot"},
			{"label": "Plot x^2",             "input": "x^2",             "cmd": "",  "kind": "plot"},
			{"label": "Plot 1/(x^2+1)",       "input": "1/(x^2+1)",       "cmd": "",  "kind": "plot"},
			{"label": "Plot exp(-x^2)",       "input": "exp(-x^2)",       "cmd": "",  "kind": "plot"},
			{"label": "Plot sin(x)/x",        "input": "sin(x)/x",        "cmd": "",  "kind": "plot"},
			{"label": "Plot sin(x) + a·cos(x)", "input": "sin(x) + a*cos(x)", "cmd": "", "kind": "plot"},
			{"label": "Plot tanh(x)",         "input": "tanh(x)",         "cmd": "",  "kind": "plot"},
		],
	},
]
