@tool
class_name RTSubscript
extends RichTextEffect
## Task 266 — a subscript BBCode effect (`[sub]…[/sub]`), companion to
## RTSuperscript. Each glyph in the range is shrunk and lowered.
var bbcode := "sub"


func _process_custom_fx(c: CharFXTransform) -> bool:
	c.transform = c.transform.scaled(Vector2(0.7, 0.7))
	c.offset.y += 7.0
	return true
