extends CanvasLayer

const Items = preload("res://scripts/globals/items.gd")

@onready var _level_label: Label = $LevelLabel
@onready var _hp_label: Label = $HPLabel
@onready var _xp_label: Label = $XPLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _potion_label: Label = $PotionLabel
@onready var _weapon_label: Label = $WeaponLabel
@onready var _bag_label: Label = $BagLabel

var _player: Node = null

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
		if _player == null:
			return
	_level_label.text = "Lv. %d" % _player.level
	_hp_label.text = "HP: %d / %d" % [_player.hp, _player.max_hp]
	_xp_label.text = "EXP: %d / %d" % [_player.xp, _player.xp_to_next_level()]
	_gold_label.text = "Gold: %d" % _player.gold
	_potion_label.text = "Potions: %d" % _player.inventory.get(Items.POTION, 0)
	if _player.equipped_weapon == Items.SWORD:
		_weapon_label.text = "Weapon: Sword"
	else:
		_weapon_label.text = "Weapon: —"
	var extra_swords: int = _player.inventory.get(Items.SWORD, 0)
	if extra_swords > 0:
		_bag_label.text = "Bag: Sword x%d" % extra_swords
		_bag_label.visible = true
	else:
		_bag_label.visible = false
