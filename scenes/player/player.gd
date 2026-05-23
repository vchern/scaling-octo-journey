extends CharacterBody2D

const Items = preload("res://scripts/globals/items.gd")

enum State { IDLE, RUN, JUMP, FALL, CLIMB }

@export_group("Movement")
@export var max_run_speed: float = 280.0
@export var ground_accel: float = 2200.0
@export var ground_friction: float = 2600.0
@export var air_accel: float = 1500.0
@export var air_friction: float = 600.0

@export_group("Jump")
@export var jump_velocity: float = -780.0
@export var jump_release_cut: float = 0.3
@export var coyote_frames: int = 6
@export var jump_buffer_frames: int = 6

@export_group("Gravity")
@export var gravity: float = 2400.0
@export var fall_gravity: float = 1800.0
@export var max_fall_speed: float = 1400.0

@export_group("Drop-through")
@export var drop_through_frames: int = 10

@export_group("Climb")
@export var climb_speed: float = 200.0
@export var rope_release_horizontal: float = 200.0
@export var rope_release_vertical: float = -400.0
@export var rope_grab_cooldown_frames: int = 6
@export var jump_grab_lift: float = 20.0

@export_group("Combat")
@export var max_hp: int = 100
@export var attack_damage: int = 1
@export var attack_duration_frames: int = 12
@export var attack_active_start_frame: int = 4
@export var attack_active_end_frame: int = 8
@export var attack_hitbox_offset: float = 32.0
@export var hit_stun_frames: int = 12
@export var i_frame_frames: int = 60
@export var hit_knockback_horizontal: float = 250.0
@export var hit_knockback_vertical: float = -200.0

@export_group("Progression")
@export var xp_to_next_base: int = 50
@export var xp_to_next_per_level: int = 25
@export var hp_per_level: int = 10
@export var attack_per_level: int = 1

@export_group("Inventory")
@export var pickup_radius: float = 28.0
@export var sword_attack_bonus: int = 5
@export var potion_heal_amount: int = 30

@export_group("Safety")
@export var fall_limit: float = 900.0
@export var respawn_position: Vector2 = Vector2(200, 596)

const ONE_WAY_LAYER_BIT := 3

var state: State = State.IDLE
var facing: int = 1
var hp: int = 0
var level: int = 1
var xp: int = 0
var gold: int = 0
var inventory: Dictionary = {}
var equipped_weapon: String = ""
var _coyote: int = 0
var _jump_buffer: int = 0
var _drop_through: int = 0
var _on_one_way: bool = false
var _current_rope: Area2D = null
var _rope_grab_cooldown: int = 0
var _climb_left_floor: bool = false
var _attack_timer: int = 0
var _attack_hit_ids: Array[int] = []
var _hit_stun: int = 0
var _i_frames: int = 0

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _hitbox: Area2D = $Hitbox

func _ready() -> void:
	hp = max_hp

func _draw() -> void:
	var body_color := Color(0.2, 0.4, 0.9)
	@warning_ignore("integer_division")
	var flash_frame: int = _i_frames / 4
	if _i_frames > 0 and flash_frame % 2 == 0:
		body_color = Color(1.0, 0.6, 0.6)
	draw_rect(Rect2(-16, -24, 32, 48), body_color)
	if _is_in_attack_active_window():
		var hb_x := float(facing) * attack_hitbox_offset
		draw_rect(Rect2(hb_x - 20.0, -20.0, 40.0, 40.0), Color(1.0, 0.3, 0.3, 0.55))

func _physics_process(delta: float) -> void:
	if global_position.y > fall_limit:
		_respawn()
		return

	if state == State.CLIMB:
		_climb_step(delta)
		_check_pickups()
		_try_use_potion()
		queue_redraw()
		return

	var input_x := Input.get_axis(&"move_left", &"move_right")
	var on_floor := is_on_floor()

	_tick_timers(on_floor)
	_buffer_inputs(on_floor)
	_try_attack_input()
	_try_use_potion()
	_try_grab_rope()
	if state == State.CLIMB:
		_check_pickups()
		queue_redraw()
		return

	var effective_input_x := input_x
	if _attack_timer > 0 or _hit_stun > 0:
		effective_input_x = 0.0

	if _hit_stun > 0:
		_apply_gravity(on_floor, delta)
	else:
		_apply_horizontal(effective_input_x, on_floor, delta)
		_apply_gravity(on_floor, delta)
		_consume_buffered_jump()

	move_and_slide()
	_update_floor_type()
	_update_state(effective_input_x)
	_update_facing(input_x)
	_update_hitbox_position()
	_process_attack()
	_check_contact_damage()
	_check_pickups()
	queue_redraw()

func _respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	hp = max_hp
	_coyote = 0
	_jump_buffer = 0
	_drop_through = 0
	_rope_grab_cooldown = 0
	_climb_left_floor = false
	_on_one_way = false
	_current_rope = null
	_attack_timer = 0
	_attack_hit_ids.clear()
	_hit_stun = 0
	_i_frames = 0
	state = State.IDLE
	set_collision_mask_value(ONE_WAY_LAYER_BIT, true)

func _tick_timers(on_floor: bool) -> void:
	if on_floor:
		_coyote = coyote_frames
	elif _coyote > 0:
		_coyote -= 1

	if _jump_buffer > 0:
		_jump_buffer -= 1

	if _rope_grab_cooldown > 0:
		_rope_grab_cooldown -= 1

	if _hit_stun > 0:
		_hit_stun -= 1

	if _i_frames > 0:
		_i_frames -= 1

	if _drop_through > 0:
		_drop_through -= 1
		if _drop_through == 0:
			set_collision_mask_value(ONE_WAY_LAYER_BIT, true)

func _buffer_inputs(on_floor: bool) -> void:
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer = jump_buffer_frames

	if Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= jump_release_cut

	if on_floor and _on_one_way and Input.is_action_pressed(&"move_down") and Input.is_action_just_pressed(&"jump"):
		set_collision_mask_value(ONE_WAY_LAYER_BIT, false)
		_drop_through = drop_through_frames
		velocity.y = max(velocity.y, 50.0)
		_jump_buffer = 0

func _try_attack_input() -> void:
	if state == State.CLIMB:
		return
	if _attack_timer > 0:
		return
	if _hit_stun > 0:
		return
	if Input.is_action_just_pressed(&"attack"):
		_start_attack()

func _start_attack() -> void:
	_attack_timer = attack_duration_frames
	_attack_hit_ids.clear()

func _apply_horizontal(input_x: float, on_floor: bool, delta: float) -> void:
	var accel := ground_accel if on_floor else air_accel
	var friction := ground_friction if on_floor else air_friction

	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * max_run_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _apply_gravity(on_floor: bool, delta: float) -> void:
	if not on_floor:
		var g := fall_gravity if velocity.y > 0.0 else gravity
		velocity.y = min(velocity.y + g * delta, max_fall_speed)

func _consume_buffered_jump() -> void:
	if _jump_buffer > 0 and _coyote > 0 and _drop_through == 0:
		velocity.y = jump_velocity
		_jump_buffer = 0
		_coyote = 0

func _try_grab_rope() -> void:
	if _rope_grab_cooldown > 0:
		return
	if _attack_timer > 0 or _hit_stun > 0:
		return
	if _drop_through > 0:
		return

	var up_pressed := Input.is_action_pressed(&"move_up")
	var down_just := Input.is_action_just_pressed(&"move_down")
	if not up_pressed and not down_just:
		return

	var is_top_grab_from_platform := down_just and is_on_floor()
	var rope := _find_overlapping_rope(is_top_grab_from_platform)
	if rope == null:
		return

	var at_top_edge := absf(global_position.y + 24.0 - rope.top_position().y) < 4.0
	if is_top_grab_from_platform and not at_top_edge:
		return

	var was_airborne := not is_on_floor()
	_current_rope = rope
	state = State.CLIMB
	global_position.x = rope.global_position.x
	if was_airborne and up_pressed:
		global_position.y = max(global_position.y - jump_grab_lift, rope.top_position().y - 24.0)
	elif is_top_grab_from_platform:
		set_collision_mask_value(ONE_WAY_LAYER_BIT, false)
		_drop_through = drop_through_frames
		global_position.y = rope.top_position().y - 24.0 + 8.0
	velocity = Vector2.ZERO
	_climb_left_floor = was_airborne

func _find_overlapping_rope(allow_top_edge: bool = false) -> Area2D:
	for rope in get_tree().get_nodes_in_group(&"ropes"):
		if not (rope is Area2D):
			continue
		var r := rope as Area2D
		if allow_top_edge:
			var feet_y: float = global_position.y + 24.0
			var rope_top_y: float = r.top_position().y
			if absf(global_position.x - r.global_position.x) < 24.0 and absf(feet_y - rope_top_y) < 4.0:
				return r
			continue
		if not r.overlaps_body(self):
			continue
		if is_on_floor() and absf(global_position.y + 24.0 - r.top_position().y) < 2.0:
			continue
		return r
	return null

func _climb_step(_delta: float) -> void:
	if _current_rope == null:
		state = State.FALL
		velocity = Vector2.ZERO
		return

	var input_y := Input.get_axis(&"move_up", &"move_down")
	velocity = Vector2(0.0, input_y * climb_speed)
	move_and_slide()
	global_position.x = _current_rope.global_position.x

	if not is_on_floor():
		_climb_left_floor = true
	elif _climb_left_floor and not Input.is_action_pressed(&"move_up"):
		_release_rope(false)
		return

	var rope_top_y: float = _current_rope.top_position().y
	var rope_bottom_y: float = _current_rope.bottom_position().y

	if Input.is_action_just_pressed(&"jump"):
		_release_rope(true)
		return

	if global_position.y + 24.0 <= rope_top_y:
		global_position.y = rope_top_y - 24.0
		if _drop_through > 0:
			_drop_through = 0
			set_collision_mask_value(ONE_WAY_LAYER_BIT, true)
		_release_rope(false)
		return

	if global_position.y + 24.0 >= rope_bottom_y and Input.is_action_pressed(&"move_down"):
		_release_rope(false)
		return

	global_position.y = clampf(global_position.y, rope_top_y - 24.0, rope_bottom_y - 24.0)

func _release_rope(with_jump: bool) -> void:
	_current_rope = null
	_climb_left_floor = false
	_rope_grab_cooldown = rope_grab_cooldown_frames
	if with_jump:
		velocity = Vector2(facing * rope_release_horizontal, rope_release_vertical)
		state = State.JUMP
	else:
		velocity = Vector2.ZERO
		state = State.FALL

func _update_floor_type() -> void:
	if not is_on_floor():
		_on_one_way = false
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y < -0.5:
			var body := col.get_collider()
			_on_one_way = body != null and body.is_in_group(&"one_way_platforms")
			return

func _update_state(input_x: float) -> void:
	if not is_on_floor():
		state = State.JUMP if velocity.y < 0.0 else State.FALL
	elif absf(input_x) > 0.01 and absf(velocity.x) > 1.0:
		state = State.RUN
	else:
		state = State.IDLE

func _update_facing(input_x: float) -> void:
	if _attack_timer > 0 or _hit_stun > 0:
		return
	if input_x > 0.0:
		facing = 1
	elif input_x < 0.0:
		facing = -1

func _update_hitbox_position() -> void:
	if _hitbox != null:
		_hitbox.position.x = float(facing) * attack_hitbox_offset

func _is_in_attack_active_window() -> bool:
	if _attack_timer <= 0:
		return false
	var active_frame := attack_duration_frames - _attack_timer
	return active_frame >= attack_active_start_frame and active_frame <= attack_active_end_frame

func _process_attack() -> void:
	if _attack_timer <= 0:
		return
	_attack_timer -= 1
	if not _is_in_attack_active_window():
		return
	if _hitbox == null:
		return
	for area in _hitbox.get_overlapping_areas():
		_try_hit_target(area)

func _try_hit_target(hurtbox: Area2D) -> void:
	var target := hurtbox.get_parent()
	if target == null or not is_instance_valid(target):
		return
	if not target.is_in_group(&"enemies"):
		return
	var id := target.get_instance_id()
	if id in _attack_hit_ids:
		return
	_attack_hit_ids.append(id)
	if target.has_method(&"take_damage"):
		target.take_damage(attack_damage, facing)

func _check_contact_damage() -> void:
	if _i_frames > 0:
		return
	if _hurtbox == null:
		return
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_hitbox := enemy.get_node_or_null(^"Hitbox") as Area2D
		if enemy_hitbox == null or not enemy_hitbox.monitoring:
			continue
		if enemy_hitbox.overlaps_area(_hurtbox):
			var direction := 1 if enemy.global_position.x < global_position.x else -1
			var dmg: int = enemy.contact_damage if "contact_damage" in enemy else 10
			take_damage(dmg, direction)
			return

func _check_pickups() -> void:
	for drop in get_tree().get_nodes_in_group(&"drops"):
		if not is_instance_valid(drop):
			continue
		if drop.global_position.distance_to(global_position) < pickup_radius:
			pick_up(drop.item_id)
			drop.queue_free()

func pick_up(item_id: String) -> void:
	if item_id == Items.COIN:
		gold += 1
		return
	inventory[item_id] = inventory.get(item_id, 0) + 1
	if item_id == Items.SWORD and equipped_weapon == "":
		equip_weapon(Items.SWORD)

func use_potion() -> void:
	if inventory.get(Items.POTION, 0) <= 0 or hp >= max_hp:
		return
	inventory[Items.POTION] -= 1
	if inventory[Items.POTION] <= 0:
		inventory.erase(Items.POTION)
	hp = min(hp + potion_heal_amount, max_hp)
	_spawn_heal_popup()

func equip_weapon(item_id: String) -> void:
	if equipped_weapon != "":
		return
	if inventory.get(item_id, 0) <= 0:
		return
	inventory[item_id] -= 1
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	equipped_weapon = item_id
	if item_id == Items.SWORD:
		attack_damage += sword_attack_bonus

func unequip_weapon() -> void:
	if equipped_weapon == "":
		return
	var item_id := equipped_weapon
	if item_id == Items.SWORD:
		attack_damage -= sword_attack_bonus
	inventory[item_id] = inventory.get(item_id, 0) + 1
	equipped_weapon = ""

func _try_use_potion() -> void:
	if Input.is_action_just_pressed(&"use_item"):
		use_potion()

func _spawn_heal_popup() -> void:
	var scene: PackedScene = load("res://scenes/vfx/damage_number.tscn")
	if scene == null:
		return
	var popup := scene.instantiate() as Node2D
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0.0, -36.0)
	if popup.has_method(&"display_text"):
		popup.display_text("+%d" % potion_heal_amount, Color(0.4, 1.0, 0.5))

func take_damage(amount: int, knockback_direction: int) -> void:
	if _i_frames > 0:
		return
	hp -= amount
	_i_frames = i_frame_frames
	_hit_stun = hit_stun_frames
	velocity = Vector2(float(knockback_direction) * hit_knockback_horizontal, hit_knockback_vertical)
	_attack_timer = 0
	_spawn_damage_number(amount)
	if hp <= 0:
		_respawn()

func _spawn_damage_number(amount: int) -> void:
	var scene: PackedScene = load("res://scenes/vfx/damage_number.tscn")
	if scene == null:
		return
	var dn := scene.instantiate() as Node2D
	get_parent().add_child(dn)
	dn.global_position = global_position + Vector2(0.0, -32.0)
	if dn.has_method(&"display"):
		dn.display(amount, Color(1.0, 0.5, 0.5))

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		_level_up()

func xp_to_next_level() -> int:
	return xp_to_next_base + (level - 1) * xp_to_next_per_level

func _level_up() -> void:
	level += 1
	max_hp += hp_per_level
	attack_damage += attack_per_level
	hp = max_hp
	_spawn_level_up_popup()

func _spawn_level_up_popup() -> void:
	var scene: PackedScene = load("res://scenes/vfx/damage_number.tscn")
	if scene == null:
		return
	var popup := scene.instantiate() as Node2D
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0.0, -40.0)
	if popup.has_method(&"display_text"):
		popup.display_text("LEVEL UP!", Color(1.0, 0.85, 0.2))
