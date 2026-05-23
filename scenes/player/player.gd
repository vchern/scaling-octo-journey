extends CharacterBody2D

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

@export_group("Safety")
@export var fall_limit: float = 900.0
@export var respawn_position: Vector2 = Vector2(200, 596)

const ONE_WAY_LAYER_BIT := 3

var state: State = State.IDLE
var facing: int = 1
var _coyote: int = 0
var _jump_buffer: int = 0
var _drop_through: int = 0
var _on_one_way: bool = false
var _current_rope: Area2D = null
var _rope_grab_cooldown: int = 0
var _climb_left_floor: bool = false

func _draw() -> void:
	draw_rect(Rect2(-16, -24, 32, 48), Color(0.2, 0.4, 0.9))

func _physics_process(delta: float) -> void:
	if global_position.y > fall_limit:
		_respawn()
		return

	if state == State.CLIMB:
		_climb_step(delta)
		return

	var input_x := Input.get_axis(&"move_left", &"move_right")
	var on_floor := is_on_floor()

	_tick_timers(on_floor)
	_buffer_inputs(on_floor)
	_try_grab_rope()
	if state == State.CLIMB:
		return

	_apply_horizontal(input_x, on_floor, delta)
	_apply_gravity(on_floor, delta)
	_consume_buffered_jump()
	move_and_slide()
	_update_floor_type()
	_update_state(input_x)
	_update_facing(input_x)

func _respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	_coyote = 0
	_jump_buffer = 0
	_drop_through = 0
	_rope_grab_cooldown = 0
	_climb_left_floor = false
	_on_one_way = false
	_current_rope = null
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
	if not Input.is_action_pressed(&"move_up"):
		return
	var rope := _find_overlapping_rope()
	if rope == null:
		return
	var was_airborne := not is_on_floor()
	_current_rope = rope
	state = State.CLIMB
	global_position.x = rope.global_position.x
	if was_airborne:
		global_position.y = max(global_position.y - jump_grab_lift, rope.top_position().y - 24.0)
	velocity = Vector2.ZERO
	_climb_left_floor = was_airborne

func _find_overlapping_rope() -> Area2D:
	for rope in get_tree().get_nodes_in_group(&"ropes"):
		if rope is Area2D and (rope as Area2D).overlaps_body(self):
			return rope as Area2D
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
		global_position.y = rope_top_y - 28.0
		_release_rope(false)
		return

	if global_position.y + 24.0 >= rope_bottom_y and Input.is_action_pressed(&"move_down"):
		_release_rope(false)
		return

	global_position.y = clampf(global_position.y, rope_top_y - 24.0, rope_bottom_y - 24.0)

func _release_rope(with_jump: bool) -> void:
	_current_rope = null
	_climb_left_floor = false
	if with_jump:
		velocity = Vector2(facing * rope_release_horizontal, rope_release_vertical)
		state = State.JUMP
		_rope_grab_cooldown = rope_grab_cooldown_frames
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
	if input_x > 0.0:
		facing = 1
	elif input_x < 0.0:
		facing = -1
