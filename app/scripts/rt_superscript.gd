@tool
class_name RTSuperscript
extends RichTextEffect
## Task 266 — a superscript BBCode effect. Godot 4.6's RichTextLabel has no
## built-in `[sup]` tag, so `[sup]…[/sup]` is provided here: each glyph in the
## range is shrunk and raised. Installed per result cell in notebook_view.
var bbcode := "sup"


func _process_custom_fx(c: CharFXTransform) -> bool:
	c.transform = c.transform.scaled(Vector2(0.7, 0.7))
	c.offset.y -= 12.0
	return true
