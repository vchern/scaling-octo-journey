extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var arrival_position: Vector2 = Vector2(200, 596)
@export var color: Color = Color(0.6, 0.4, 0.9, 0.75)
@export var size: Vector2 = Vector2(48, 80)

var _triggered: bool = false
var _player_overlapping: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _draw() -> void:
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	draw_rect(Rect2(-hw, -hh, size.x, size.y), color)
	draw_rect(Rect2(-hw, -hh, size.x, size.y), Color(1, 1, 1, 0.4), false, 2.0)
	if _player_overlapping:
		var font := ThemeDB.fallback_font
		var font_size := 16
		var text := "Press ↑"
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos := Vector2(-text_size.x * 0.5, -hh - 14.0)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 1))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 1))

func _process(_delta: float) -> void:
	if _triggered:
		return
	if not _player_overlapping:
		return
	if not Input.is_action_just_pressed(&"move_up"):
		return
	_activate()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	_player_overlapping = true
	queue_redraw()

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	_player_overlapping = false
	queue_redraw()

func _activate() -> void:
	if target_scene_path == "":
		return
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	_triggered = true
	if player.has_method(&"save_state"):
		player.save_state()
	Transition.set_next_spawn(arrival_position)
	await FadeOverlay.fade_to_black(0.3)
	get_tree().change_scene_to_file(target_scene_path)
