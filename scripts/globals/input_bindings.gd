extends Node

func _ready() -> void:
	_register(&"move_left", [KEY_LEFT, KEY_A])
	_register(&"move_right", [KEY_RIGHT, KEY_D])
	_register(&"move_up", [KEY_UP, KEY_W])
	_register(&"move_down", [KEY_DOWN, KEY_S])
	_register(&"jump", [KEY_SPACE, KEY_ALT])
	_register(&"attack", [KEY_CTRL, KEY_J])
	_register(&"skill_1", [KEY_X, KEY_K])
	_register(&"skill_2", [KEY_C, KEY_L])
	_register(&"use_item", [KEY_U])
	_register(&"toggle_inventory", [KEY_I])
	_register(&"reset_save", [KEY_F8])

func _register(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for k in keys:
		var event := InputEventKey.new()
		event.physical_keycode = k
		InputMap.action_add_event(action, event)
