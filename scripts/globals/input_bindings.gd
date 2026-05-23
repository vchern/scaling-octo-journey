extends Node

func _ready() -> void:
	_register(&"move_left", [KEY_LEFT, KEY_A])
	_register(&"move_right", [KEY_RIGHT, KEY_D])
	_register(&"move_up", [KEY_UP, KEY_W])
	_register(&"move_down", [KEY_DOWN, KEY_S])
	_register(&"jump", [KEY_SPACE])
	_register(&"attack", [KEY_Z, KEY_J])
	_register(&"skill_1", [KEY_X, KEY_K])
	_register(&"skill_2", [KEY_C, KEY_L])
	_register(&"use_item", [KEY_U])

func _register(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for k in keys:
		var event := InputEventKey.new()
		event.physical_keycode = k
		InputMap.action_add_event(action, event)
