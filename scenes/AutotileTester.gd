extends TilePlacerStateMachine

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
const MIN_ZOOM := Vector2.ONE * 0.2
const MAX_ZOOM := Vector2.ONE * 2.5
var MIN_ZOOM_LENGTH := MIN_ZOOM.length()
var MAX_ZOOM_LENGTH := MAX_ZOOM.length()

var lights := {}
var tile_light_energy := 1.2
var tile_light_enabled := true

var has_previous_pos := false
var previous_pos := Vector2()

var hint_start_tile := Vector2()

var panning := false

onready var grid_lighter := $GridLighter
onready var texture := tile_set.tile_get_texture(0)
onready var hint_draw := $HintDraw
onready var grid_sprite := $Grid/GridSprite
onready var camera := $Camera2D


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
	if event is InputEventWithModifiers:
		if event.shift and (event.command or event.control):
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
			hint_draw.update()
		states.draw:
			pass
		states.erase:
			pass
		states.rect_draw:
			hint_start_tile = world_to_map(get_global_mouse_position())
		states.rect_erase:
			hint_start_tile = world_to_map(get_global_mouse_position())


func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			pass
		states.draw:
			pass
		states.erase:
			pass
		states.rect_draw:
			draw_rect_tiles(hint_start_tile,
					world_to_map(get_global_mouse_position()), 0)
		states.rect_erase:
			draw_rect_tiles(hint_start_tile,
					world_to_map(get_global_mouse_position()), -1)


func _process(delta: float) -> void:
	grid_lighter.position = get_global_mouse_position()
	match state:
		states.draw:
			draw_tile(0)
		states.erase:
			draw_tile(-1)
		states.rect_draw:
			hint_draw.update()
		states.rect_erase:
			hint_draw.update()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pan", false, true):
		panning = true
	elif event.is_action_released("pan", true):
		panning = false
	elif panning and event is InputEventMouseMotion:
		camera.position -= event.relative * camera.zoom
	elif event is InputEventMouseButton:
		event.factor = 1 * camera.zoom.x
		if event.button_index == 4:
			var min_cell_size_factor := min(cell_size.x, cell_size.y) / 24
			# Scroll Up
			var new_zoom = (camera.zoom - (Vector2.ONE * event.factor / 10))
			if new_zoom.length() < MIN_ZOOM_LENGTH * min_cell_size_factor\
					 or new_zoom.x < 0 or new_zoom.y < 0:
				new_zoom = MIN_ZOOM * min_cell_size_factor
			camera.zoom = new_zoom
			grid_sprite.zoom = camera.zoom
		elif event.button_index == 5:
			var max_cell_size_factor := max(cell_size.x, cell_size.y) / 24
			# Scroll Down
			var new_zoom = (camera.zoom + (Vector2.ONE * event.factor / 10))\
					.limit_length(MAX_ZOOM_LENGTH * \
					max_cell_size_factor)
			camera.zoom = new_zoom
			grid_sprite.zoom = camera.zoom


func get_world_rect_bounds(p1: Vector2, p2: Vector2) -> Rect2:
	var x := p1.x
	var y := p1.y
	var dx := p2.x - p1.x
	var dy := p2.y - p1.y
	if dx < 0:
		x += 1
		dx -= 1
	else:
		dx += 1
	if dy < 0:
		y += 1
		dy -= 1
	else:
		dy += 1
	return Rect2(x * cell_size.x, y * cell_size.y,
			dx * cell_size.x, dy * cell_size.y).abs()


func get_map_rect_bounds(p1: Vector2, p2: Vector2) -> Rect2:
	var x := p1.x
	var y := p1.y
	var dx := p2.x - p1.x
	var dy := p2.y - p1.y
	if dx < 0:
		x += 1
		dx -= 1
	else:
		dx += 1
	if dy < 0:
		y += 1
		dy -= 1
	else:
		dy += 1
	return Rect2(x, y, dx, dy).abs()


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


func _on_Controls_file_changed(texture) -> void:
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


func _on_Controls_cell_size_changed(p_cell_size: Vector2) -> void:
	var ratio := max(p_cell_size.x, p_cell_size.y) / \
			max(cell_size.x, cell_size.y)
	camera.position *= ratio
	camera.zoom *= ratio
	cell_size = p_cell_size
	grid_sprite.cell_size = p_cell_size
	grid_sprite.zoom = camera.zoom
	var light_scale := max(p_cell_size.x, p_cell_size.y) / 24
	grid_lighter.texture_scale = light_scale
	for pos in lights:
		lights[pos].position = pos * cell_size + cell_size / 2
		lights[pos].texture_scale = light_scale


func _on_Controls_subtile_size_changed(subtile_size: Vector2) -> void:
	tile_set.autotile_set_size(0, subtile_size)
	update_bitmask_region()
