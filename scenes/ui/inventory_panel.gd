extends CanvasLayer

const Items = preload("res://scripts/globals/items.gd")

@onready var _gold_row: Label = $Panel/VBox/GoldRow
@onready var _equipped_row: Button = $Panel/VBox/EquippedRow
@onready var _items_list: VBoxContainer = $Panel/VBox/ItemsList

var _player: Node = null
var _last_signature: String = ""

func _ready() -> void:
	visible = false
	_equipped_row.pressed.connect(_on_equipped_clicked)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"toggle_inventory"):
		visible = not visible
		if visible:
			_last_signature = ""  # force rebuild on open
			_refresh()
		return
	if visible and Input.is_action_just_pressed(&"ui_cancel"):
		visible = false
		return
	if visible:
		_refresh()

func _refresh() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
		if _player == null:
			return

	var sig := _state_signature()
	if sig == _last_signature:
		return
	_last_signature = sig

	_gold_row.text = "Gold: %d" % _player.gold
	if _player.equipped_weapon == Items.SWORD:
		_equipped_row.text = "Equipped: Sword  (click to unequip)"
		_equipped_row.disabled = false
	elif _player.equipped_weapon != "":
		_equipped_row.text = "Equipped: %s  (click to unequip)" % Items.display_name(_player.equipped_weapon)
		_equipped_row.disabled = false
	else:
		_equipped_row.text = "Equipped: —"
		_equipped_row.disabled = true

	for child in _items_list.get_children():
		child.queue_free()

	var any_rows := false
	for item_id in _player.inventory:
		var count: int = _player.inventory[item_id]
		if count <= 0:
			continue
		_items_list.add_child(_make_item_row(item_id, count))
		any_rows = true

	if not any_rows:
		var empty := Label.new()
		empty.text = "(empty)"
		empty.modulate = Color(1, 1, 1, 0.5)
		_items_list.add_child(empty)

func _state_signature() -> String:
	var parts := PackedStringArray()
	parts.append(str(_player.gold))
	parts.append(_player.equipped_weapon)
	var keys: Array = _player.inventory.keys()
	keys.sort()
	for k in keys:
		parts.append("%s:%d" % [k, _player.inventory[k]])
	return "|".join(parts)

func _make_item_row(item_id: String, count: int) -> Button:
	var row := Button.new()
	row.flat = true
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_theme_color_override(&"font_color", Items.color_for(item_id))
	var verb := ""
	if item_id == Items.POTION:
		verb = "  (click to use)"
	elif item_id == Items.SWORD and _player != null and _player.equipped_weapon == "":
		verb = "  (click to equip)"
	row.text = "%s x %d%s" % [Items.display_name(item_id), count, verb]
	row.pressed.connect(_on_item_clicked.bind(item_id))
	return row

func _on_item_clicked(item_id: String) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if item_id == Items.POTION and _player.has_method(&"use_potion"):
		_player.use_potion()
	elif item_id == Items.SWORD and _player.equipped_weapon == "" and _player.has_method(&"equip_weapon"):
		_player.equip_weapon(Items.SWORD)

func _on_equipped_clicked() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.equipped_weapon != "" and _player.has_method(&"unequip_weapon"):
		_player.unequip_weapon()
