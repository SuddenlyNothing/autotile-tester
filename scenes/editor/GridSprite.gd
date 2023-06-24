tool
extends ParallaxLayer

var true_size := Vector2(1024, 608)

export(Vector2) var cell_size := Vector2(24, 24) setget set_cell_size
export(Vector2) var camera_size := Vector2(1024, 608) setget set_camera_size
export(Vector2) var zoom := Vector2.ONE setget set_zoom


func _ready() -> void:
	set_camera_size(get_viewport_rect().size)
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")


func _draw() -> void:
	if cell_size.x == 0 or cell_size.y == 0:
		return
	for i in (true_size.x / cell_size.x):
		draw_line(Vector2(i * cell_size.x, 0), Vector2(i * cell_size.x,
				true_size.y), Color(1, 0.647059, 0, 0.2), 1.0)
	for i in (true_size.y / cell_size.y):
		draw_line(Vector2(0, i * cell_size.y), Vector2(true_size.x,
				i * cell_size.y), Color(1, 0.647059, 0, 0.2), 1.0)


func set_zoom(val: Vector2) -> void:
	zoom = val
	true_size = (camera_size * zoom / cell_size).snapped(Vector2.ONE) * \
			cell_size
	motion_mirroring = true_size
	update()


func set_cell_size(val: Vector2) -> void:
	cell_size = val
	update()


func set_camera_size(val: Vector2) -> void:
	camera_size = val
	true_size = (camera_size * zoom / cell_size).snapped(Vector2.ONE) * \
			cell_size
	motion_mirroring = true_size
	update()


func _on_viewport_size_changed() -> void:
	set_camera_size(get_viewport_rect().size)
