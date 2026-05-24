extends CanvasLayer

@onready var _rect: ColorRect = $Rect

func _ready() -> void:
	_rect.modulate.a = 0.0

func fade_to_black(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, duration)
	await tween.finished
