extends Area2D

@export var climb_length: float = 200.0:
	set(value):
		climb_length = value
		_update_geometry()

func _ready() -> void:
	add_to_group(&"ropes")
	_update_geometry()

func _update_geometry() -> void:
	var shape_node := get_node_or_null(^"Shape") as CollisionShape2D
	var visual_node := get_node_or_null(^"Visual") as Polygon2D
	if shape_node != null:
		var s := RectangleShape2D.new()
		s.size = Vector2(16.0, climb_length)
		shape_node.shape = s
	if visual_node != null:
		var h := climb_length * 0.5
		visual_node.polygon = PackedVector2Array([
			Vector2(-2, -h),
			Vector2(2, -h),
			Vector2(2, h),
			Vector2(-2, h),
		])

func top_position() -> Vector2:
	return global_position + Vector2(0.0, -climb_length * 0.5)

func bottom_position() -> Vector2:
	return global_position + Vector2(0.0, climb_length * 0.5)
