extends Node2D

var disabled := false setget set_disabled
var highlighting := false setget set_highlighting
var highlight_coord := Vector2() setget set_highlight_coord

var cell_size := Vector2(24, 24) setget set_cell_size
var subtile_size := Vector2(24, 24) setget set_subtile_size


func set_cell_size(val: Vector2) -> void:
	cell_size = val
	update()


func set_subtile_size(val: Vector2) -> void:
	subtile_size = val
	update()


func set_disabled(val: bool) -> void:
	if disabled == val:
		return
	disabled = val
	update()


func set_highlighting(val: bool) -> void:
	if highlighting == val:
		return
	highlighting = val
	update()


func set_highlight_coord(val: Vector2) -> void:
	highlight_coord = val
	update()


func _draw() -> void:
	if disabled or not highlighting:
		return
	var subtile_rect := Rect2(highlight_coord * cell_size, subtile_size)
	draw_rect(subtile_rect, Color(0.6, 0.1, 0.9, 0.3))
	draw_rect(subtile_rect,
			Color.purple, false)
	draw_rect(Rect2(highlight_coord * cell_size, cell_size),
			Color.purple, false)
