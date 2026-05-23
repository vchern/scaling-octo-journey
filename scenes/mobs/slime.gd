extends CharacterBody2D

@export var max_hp: int = 3
@export var move_speed: float = 60.0
@export var contact_damage: int = 10
@export var gravity: float = 2400.0
@export var max_fall_speed: float = 1400.0
@export var knockback_horizontal: float = 200.0
@export var knockback_vertical: float = -300.0
@export var hit_stun_frames: int = 12
@export var death_fade_seconds: float = 0.5
@export var respawn_seconds: float = 3.0
@export var xp_reward: int = 10

var hp: int = 0
var _facing: int = 1
var _hit_stun: int = 0
var _dying: bool = false
var _dead: bool = false
var _spawn_position: Vector2

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group(&"enemies")
	_spawn_position = global_position
	hp = max_hp

func _draw() -> void:
	if _dead:
		return
	draw_rect(Rect2(-16, -16, 32, 32), Color(0.4, 0.85, 0.4))

func _physics_process(delta: float) -> void:
	if _dead:
		return

	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	if _dying:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	if _hit_stun > 0:
		_hit_stun -= 1
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return

	velocity.x = float(_facing) * move_speed
	move_and_slide()

	if is_on_floor() and (is_on_wall() or _is_ledge_ahead()):
		_facing = -_facing

	_apply_contact_damage()

func _is_ledge_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(float(_facing) * 20.0, 0.0)
	var to := from + Vector2(0.0, 40.0)
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 2
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()

func _apply_contact_damage() -> void:
	if _hitbox == null:
		return
	for area in _hitbox.get_overlapping_areas():
		var target := area.get_parent()
		if target == null or not is_instance_valid(target):
			continue
		if not target.is_in_group(&"player"):
			continue
		var direction := 1 if target.global_position.x >= global_position.x else -1
		if target.has_method(&"take_damage"):
			target.take_damage(contact_damage, direction)

func take_damage(amount: int, knockback_direction: int) -> void:
	if _dying or _dead:
		return
	hp -= amount
	_hit_stun = hit_stun_frames
	velocity = Vector2(float(knockback_direction) * knockback_horizontal, knockback_vertical)
	_spawn_damage_number(amount)
	if hp <= 0:
		_die()

func _spawn_damage_number(amount: int) -> void:
	var scene: PackedScene = load("res://scenes/vfx/damage_number.tscn")
	if scene == null:
		return
	var dn := scene.instantiate() as Node2D
	get_parent().add_child(dn)
	dn.global_position = global_position + Vector2(0.0, -22.0)
	if dn.has_method(&"display"):
		dn.display(amount, Color(1.0, 0.95, 0.7))

func _die() -> void:
	_dying = true
	if _hurtbox != null:
		_hurtbox.monitorable = false
	if _hitbox != null:
		_hitbox.monitoring = false
	_award_xp()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, death_fade_seconds)
	tween.tween_callback(_on_fade_complete)

func _award_xp() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"gain_xp"):
		player.gain_xp(xp_reward)

func _on_fade_complete() -> void:
	_dead = true
	visible = false
	var timer := get_tree().create_timer(respawn_seconds)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	global_position = _spawn_position
	hp = max_hp
	velocity = Vector2.ZERO
	_facing = 1
	_hit_stun = 0
	_dying = false
	_dead = false
	visible = true
	modulate.a = 1.0
	if _hurtbox != null:
		_hurtbox.monitorable = true
	if _hitbox != null:
		_hitbox.monitoring = true
