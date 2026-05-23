extends Node2D

@export var float_height: float = 36.0
@export var lifetime_seconds: float = 0.6

func display(amount: int, color: Color = Color.WHITE) -> void:
	display_text(str(amount), color)

func display_text(text: String, color: Color = Color.WHITE) -> void:
	var label := $Label as Label
	label.text = text
	label.add_theme_color_override(&"font_color", color)
	var start_y := position.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start_y - float_height, lifetime_seconds)
	tween.tween_property(self, "modulate:a", 0.0, lifetime_seconds).set_delay(lifetime_seconds * 0.4)
	tween.chain().tween_callback(queue_free)
