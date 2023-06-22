extends TilePlacerStateMachine

#enum TOOLS {
#	NONE,
#	DRAW,
#	ERASE,
#	LINE,
#	RECT,
#}

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

var lights := {}
var tile_light_energy := 0.7
var tile_light_enabled := true

var has_previous_pos := false
var previous_pos := Vector2()

onready var grid_lighter := $GridLighter
onready var texture := tile_set.tile_get_texture(0)
onready var select := $Select


func _ready() -> void:
	add_state("idle")
	add_state("draw")
	add_state("erase")
	add_state("rect_draw")
	add_state("rect_erase")
	call_deferred("set_state", "idle")


# Return value will be used to change state.
func _get_transition(event: InputEvent):
	# Draw and erase
	if event.is_action_pressed("draw", false, true):
		return states.draw
	elif event.is_action_pressed("erase", false, true):
		return states.erase
	
	# Rect draw and erase
	if Input.is_action_pressed("rect"):
		if event.is_action_pressed("draw"):
			return states.rect_draw
		elif event.is_action_pressed("erase"):
			return states.rect_erase
	
	# Release rect draw and erase and normal draw and erase
	if event.is_action_released("draw", false):
		return states.idle
	elif event.is_action_released("erase", false):
		return states.idle
	return null


func _enter_state(new_state: String, old_state) -> void:
	match new_state:
		states.idle:
			has_previous_pos = false
		states.draw:
			pass
		states.erase:
			pass
		states.rect_draw:
			pass
		states.rect_erase:
			pass


func _exit_state(old_state, new_state: String) -> void:
	match new_state:
		states.idle:
			pass
		states.draw:
			pass
		states.erase:
			pass
		states.rect_draw:
			pass
		states.rect_erase:
			pass


func _process(delta: float) -> void:
	grid_lighter.position = get_global_mouse_position()
	match state:
		states.draw:
			draw_tile(0)
		states.erase:
			draw_tile(-1)
		states.rect_draw:
			pass
		states.rect_erase:
			pass


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
	p1 = world_to_map(p1)
	p2 = world_to_map(p2)
	var dx: int = int(abs(p1.x - p2.x))
	var dy: int = int(abs(p1.y - p2.y))
	
	var sx := sign(p2.x - p1.x)
	var sy := sign(p2.y - p1.y)
	
	var x := p1.x
	var y := p1.y
	
	var is_steep := dy > dx
	if is_steep:
		var temp := dx
		dx = dy
		dy = temp
		
		temp = x
		x = y
		y = temp
		
		temp = sx
		sx = sy
		sy = temp
	
	var error := 2 * dy - dx
	
	var points := []
	while true:
		if is_steep:
			points.append(Vector2(y, x))
			if Vector2(y, x) == p2:
				break
		else:
			points.append(Vector2(x, y))
			if Vector2(x, y) == p2:
				break
		if error >= 0:
			y += sy
			error -= dx
		x += sx
		error += dy
	return points


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
