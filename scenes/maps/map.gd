extends Node2D

func _ready() -> void:
	if Transition.has_next_spawn:
		var player := get_node_or_null(^"Player") as Node2D
		if player != null:
			var spawn := Transition.consume_spawn()
			player.global_position = spawn
			if player is CharacterBody2D:
				(player as CharacterBody2D).velocity = Vector2.ZERO
			var camera := player.get_node_or_null(^"Camera2D") as Camera2D
			if camera != null:
				camera.reset_smoothing()
	FadeOverlay.fade_from_black(0.3)
