extends Node

var next_spawn_position: Vector2 = Vector2.ZERO
var has_next_spawn: bool = false

func set_next_spawn(position: Vector2) -> void:
	next_spawn_position = position
	has_next_spawn = true

func consume_spawn() -> Vector2:
	has_next_spawn = false
	var pos := next_spawn_position
	next_spawn_position = Vector2.ZERO
	return pos

func clear() -> void:
	next_spawn_position = Vector2.ZERO
	has_next_spawn = false
