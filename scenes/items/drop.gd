extends CharacterBody2D

const Items = preload("res://scripts/globals/items.gd")

@export var gravity: float = 1600.0
@export var max_fall_speed: float = 800.0
@export var spawn_horizontal_jitter: float = 80.0
@export var spawn_upward_kick: float = 200.0

var item_id: String = ""

func _ready() -> void:
	velocity = Vector2(randf_range(-spawn_horizontal_jitter, spawn_horizontal_jitter), -spawn_upward_kick)

func setup(id: String) -> void:
	item_id = id
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), Items.color_for(item_id))

func _physics_process(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	move_and_slide()
