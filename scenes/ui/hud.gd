extends CanvasLayer

@onready var _level_label: Label = $LevelLabel
@onready var _hp_label: Label = $HPLabel
@onready var _xp_label: Label = $XPLabel

var _player: Node = null

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
		if _player == null:
			return
	_level_label.text = "Lv. %d" % _player.level
	_hp_label.text = "HP: %d / %d" % [_player.hp, _player.max_hp]
	_xp_label.text = "EXP: %d / %d" % [_player.xp, _player.xp_to_next_level()]
