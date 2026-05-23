extends CanvasLayer

@onready var _hp_label: Label = $HPLabel

var _player: Node = null

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
		if _player == null:
			return
	_hp_label.text = "HP: %d / %d" % [_player.hp, _player.max_hp]
