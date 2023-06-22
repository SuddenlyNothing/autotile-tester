tool
extends ParallaxLayer

export(Vector2) var cell_size := Vector2(24, 24) setget set_cell_size
export(Vector2) var camera_size := Vector2(1024, 608) setget set_camera_size


func _draw() -> void:
	for i in (camera_size.x / cell_size.x):
		draw_line(Vector2(i * cell_size.x, 0), Vector2(i * cell_size.x, camera_size.y),
				 Color(1, 0.647059, 0, 0.2), 1.0)
	for i in (camera_size.y / cell_size.y):
		draw_line(Vector2(0, i * cell_size.y), Vector2(camera_size.x, i * cell_size.y),
				Color(1, 0.647059, 0, 0.2), 1.0)


func set_cell_size(val: Vector2) -> void:
	cell_size = val
	update()


func set_camera_size(val: Vector2) -> void:
	val = (val / cell_size).snapped(Vector2.ONE) * cell_size
	camera_size = val
	motion_mirroring = camera_size
	update()
