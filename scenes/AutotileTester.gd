extends TilePlacerStateMachine

enum TOOLS {
	NONE,
	DRAW,
	ERASE,
	LINE,
	RECT,
}

const GridLighter := preload("res://scenes/editor/GridLighter.tscn")
const DIRECTIONS := [
	Vector2.UP,
	Vector2(1, -1),
	Vector2.RIGHT,
	Vector2.ONE,
	Vector2.DOWN,
	Vector2(-1, -1),
	Vector2.LEFT,
	Vector2(-1, 1),
]

var active_tool = TOOLS.NONE
var lights := {}
var tile_light_energy := 0.7
var tile_light_enabled := true

var has_previous_pos := false
var previous_pos := Vector2()

var tool_started := false
var tool_start_pos: Vector2
var tool_tile: int

onready var grid_lighter := $GridLighter
onready var texture := tile_set.tile_get_texture(0)
onready var select := $Select
onready var hint_tiles := $HintTiles


#func _ready() -> void:
#	add_state("idle")
#	add_state("draw")
#	add_state("erase")
#	add_state("rect_draw")
#	add_state("rect_erase")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("draw", false, true):
		active_tool = TOOLS.DRAW
	elif event.is_action_released("draw", true):
		if active_tool == TOOLS.RECT:
			tool_started = false
			hint_tiles.clear()
			hint_tiles.modulate = Color.white
			draw_rect_tiles(tool_start_pos,
					world_to_map(get_global_mouse_position()), tool_tile)
		active_tool = TOOLS.NONE
		has_previous_pos = false
	elif event.is_action_pressed("erase", false, true):
		active_tool = TOOLS.ERASE
	elif event.is_action_released("erase", true):
		if active_tool == TOOLS.RECT:
			tool_started = false
			hint_tiles.clear()
			hint_tiles.modulate = Color.white
			draw_rect_tiles(tool_start_pos,
					world_to_map(get_global_mouse_position()), tool_tile)
		active_tool = TOOLS.NONE
		has_previous_pos = false
	elif event.is_action_pressed("rect", false, true):
		active_tool = TOOLS.RECT
	elif event.is_action_released("rect", true):
		if not (Input.is_action_pressed("draw") or \
				Input.is_action_pressed("erase")) or not tool_started:
			hint_tiles.clear()
			active_tool = TOOLS.NONE


func _process(_delta: float) -> void:
	grid_lighter.position = get_global_mouse_position()
	match active_tool:
		TOOLS.DRAW:
			draw_tile(0)
		TOOLS.ERASE:
			draw_tile(-1)
		TOOLS.RECT:
			if Input.is_action_just_pressed("draw"):
				tool_started = true
				hint_tiles.modulate = Color.white
				tool_tile = 0
				tool_start_pos = world_to_map(get_global_mouse_position())
			elif tool_started and Input.is_action_just_released("draw"):
				tool_started = false
				hint_tiles.clear()
				hint_tiles.modulate = Color.white
				draw_rect_tiles(tool_start_pos,
						world_to_map(get_global_mouse_position()), 0)
			elif Input.is_action_just_pressed("erase"):
				tool_started = true
				tool_tile = -1
				hint_tiles.modulate = Color.red
				tool_start_pos = world_to_map(get_global_mouse_position())
			elif tool_started and Input.is_action_just_released("erase"):
				tool_started = false
				hint_tiles.clear()
				hint_tiles.modulate = Color.red
				draw_rect_tiles(tool_start_pos,
						world_to_map(get_global_mouse_position()), -1)
			elif not tool_started:
				if Input.is_action_pressed("erase"):
					has_previous_pos = false
					tool_started = true
					tool_tile = -1
					hint_tiles.modulate = Color.red
					tool_start_pos = world_to_map(get_global_mouse_position())
				elif Input.is_action_pressed("draw"):
					has_previous_pos = false
					tool_started = true
					hint_tiles.modulate = Color.white
					tool_tile = 0
					tool_start_pos = world_to_map(get_global_mouse_position())
			elif tool_started and (Input.is_action_pressed("erase") or \
					Input.is_action_pressed("draw")):
				if tool_started:
					hint_tiles.clear()
					var end_pos := world_to_map(get_global_mouse_position())
					for x in range(min(tool_start_pos.x, end_pos.x),
							max(end_pos.x, tool_start_pos.x) + 1):
						for y in range(min(end_pos.y, tool_start_pos.y),
								max(end_pos.y, tool_start_pos.y) + 1):
							hint_tiles.set_cell(x, y, 0)
					hint_tiles.update_bitmask_region()


func draw_tile(tile: int) -> void:
	var mouse_pos := get_global_mouse_position()
	var new_cell_pos := world_to_map(mouse_pos)
	set_cellv(new_cell_pos, tile)
	update_bitmask_area(new_cell_pos)
	if has_previous_pos:
		for i in get_tiles_between_points(mouse_pos, previous_pos):
			set_cellv(i, tile)
		update_bitmask_region()
	else:
		has_previous_pos = true
	previous_pos = mouse_pos


func draw_rect_tiles(p1: Vector2, p2: Vector2, tile: int) -> void:
	for x in range(min(p1.x, p2.x), max(p1.x, p2.x) + 1):
		for y in range(min(p1.y, p2.y), max(p1.y, p2.y) + 1):
			set_cellv(Vector2(x, y), tile)
	update_bitmask_region()


func get_tiles_between_points(p1: Vector2, p2: Vector2) -> Array:
	var tile_p1 := world_to_map(p1)
	var tile_p2 := world_to_map(p2)
	if tile_p1 == tile_p2:
		return []
	var tiles := []
	while true:
		var add_tile: Vector2 = tile_p1 + DIRECTIONS[0]
		var min_dist: float = (tile_p1 + DIRECTIONS[0])\
				.distance_squared_to(tile_p2)
		for i in range(1, len(DIRECTIONS)):
			var new_tile: Vector2 = tile_p1 + DIRECTIONS[i]
			var new_tile_dist: float = (tile_p1 + DIRECTIONS[i].normalized())\
					.distance_squared_to(tile_p2)
			if new_tile_dist < min_dist:
				min_dist = new_tile_dist
				add_tile = new_tile
		if add_tile == tile_p2:
			break
		tiles.append(add_tile)
		tile_p1 = add_tile
	return tiles


func set_cellv(pos: Vector2, tile: int, flip_x: bool = false,
		flip_y: bool = false, transpose: bool = false,
		autotile_coord: Vector2 = Vector2()) -> void:
	if tile == -1:
		if pos in lights:
			lights[pos].queue_free()
			lights.erase(pos)
	elif not pos in lights:
		var gl := GridLighter.instance()
		gl.position = map_to_world(pos) + cell_size / 2
		gl.enabled = tile_light_enabled
		gl.energy = tile_light_energy
		add_child(gl)
		lights[pos] = gl
	.set_cellv(pos, tile, flip_x, flip_y, transpose, autotile_coord)


func _on_Controls_file_changed(texture: ImageTexture) -> void:
	tile_set.tile_set_texture(0, texture)


func _on_Controls_mouse_light_changed(is_on: bool) -> void:
	grid_lighter.enabled = is_on


func _on_Controls_tiles_light_changed(is_on: bool) -> void:
	tile_light_enabled = is_on
	for key in lights:
		lights[key].enabled = is_on


func _on_Controls_mouse_strength_changed(value: float) -> void:
	grid_lighter.energy = value


func _on_Controls_tiles_strength_changed(value: float) -> void:
	tile_light_energy = value
	for key in lights:
		lights[key].energy = value
