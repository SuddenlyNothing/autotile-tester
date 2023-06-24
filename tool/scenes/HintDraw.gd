extends Node2D

onready var parent := get_parent()


func _draw() -> void:
	if parent == null:
		return
	match parent.state:
		parent.states.rect_draw:
			draw_rect(parent.get_world_rect_bounds(parent.hint_start_tile,
					parent.world_to_map(get_global_mouse_position())),
					Color(0, 0.4, 1, 0.5))
		parent.states.rect_erase:
			draw_rect(parent.get_world_rect_bounds(parent.hint_start_tile,
					parent.world_to_map(get_global_mouse_position())),
					Color(1, 0, 0, 0.5))
