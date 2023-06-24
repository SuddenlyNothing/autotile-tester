extends Control

signal file_changed(texture)
signal mouse_light_changed(is_on)
signal mouse_strength_changed(value)
signal tiles_light_changed(is_on)
signal tiles_strength_changed(value)
signal window_on_top_changed(is_on_top)
signal cell_size_changed(cell_size)
signal subtile_size_changed(subtile_size)

const Hidden := preload("res://assets/hidden.svg")
const Visible := preload("res://assets/visible.svg")

export(String, FILE, "*.png") var temp
export(String, FILE, "*.png") var thick
export(Array, String, FILE, "*.png") var anim

export(Array, String, FILE, "*.png") var curr_files

var file := File.new()
var modified_times := {}
var curr_fps := 10

var download_file := ""
var real_size := Vector2()
var texture_cell_size := Vector2()
var texture_subtile_size := Vector2()
var highlight_tile := Vector2.LEFT

export var cell_size := Vector2(24, 24)
export var subtile_size := Vector2(24, 24)

onready var file_dialog := $"%FileDialog"
onready var current_file := $"%CurrentFile"
onready var tiles_texture := $"%TilesTexture"
onready var accept_dialog := $"%AcceptDialog"
onready var fps: HBoxContainer = $"%FPS"
onready var controls: MarginContainer = $"%Controls"
onready var toggle_visibility: Button = $"%ToggleVisibility"
onready var cell_size_x: HBoxContainer = $"%CellSizeX"
onready var cell_size_y: HBoxContainer = $"%CellSizeY"
onready var subtile_size_x: HBoxContainer = $"%SubtileSizeX"
onready var subtile_size_y: HBoxContainer = $"%SubtileSizeY"
onready var save_file: FileDialog = $"%SaveFile"


func _ready() -> void:
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	set_real_texture_size()


func get_texture(path: String) -> ImageTexture:
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		return null
	var texture := ImageTexture.new()
	texture.create_from_image(image, 0)
	return texture


func load_animated_texture_paths(paths: PoolStringArray) -> void:
	for path in paths:
		if path.get_extension() != "png":
			accept_dialog.popup_centered()
			return
	fps.show()
	var anim_texture := AnimatedTexture.new()
	anim_texture.frames = paths.size()
	anim_texture.fps = curr_fps
	current_file.text = paths[0].get_file()
	curr_files = paths
	modified_times.clear()
	for i in len(paths):
		var texture := get_texture(paths[i])
		anim_texture.set_frame_texture(i, texture)
	tiles_texture.texture = anim_texture
	set_real_texture_size()
	emit_signal("file_changed", anim_texture)


func load_texture_path(path: String) -> void:
	if path.get_extension() != "png":
		accept_dialog.popup_centered()
		return
	fps.hide()
	curr_files = [path]
	current_file.text = path.get_file()
	var texture := get_texture(path)
	modified_times.clear()
	tiles_texture.texture = texture
	set_real_texture_size()
	emit_signal("file_changed", texture)


func set_real_texture_size() -> void:
	var tex_size: Vector2 = tiles_texture.texture.get_size()
	var ratio := tex_size.x / tex_size.y
	
	if tex_size.x > tex_size.y:
		real_size = Vector2(tiles_texture.rect_size.x,
				tiles_texture.rect_size.x / ratio)
	else:
		real_size = Vector2(tiles_texture.rect_size.y * ratio,
				tiles_texture.rect_size.y)
	texture_cell_size = real_size / Vector2(12, 4)


func auto_update_cell_subtile_size() -> void:
	var new_size: Vector2 = tiles_texture.texture.get_size() / Vector2(12, 4)
	cell_size_x.num = new_size.x
	cell_size_y.num = new_size.y
	subtile_size_x.num = new_size.x
	subtile_size_y.num = new_size.y


func load_files(files: PoolStringArray) -> void:
	if files.size() == 1:
		load_texture_path(files[0])
	else:
		load_animated_texture_paths(files)
	auto_update_cell_subtile_size()


func _on_files_dropped(files: PoolStringArray, screen: int) -> void:
	load_files(files)


func _on_FileDialog_files_selected(files: PoolStringArray) -> void:
	load_files(files)


func _on_ChangeFile_pressed() -> void:
	file_dialog.popup_centered()


func _on_MouseGrid_toggled(button_pressed: bool) -> void:
	emit_signal("mouse_light_changed", button_pressed)


func _on_TilesGrid_toggled(button_pressed: bool) -> void:
	emit_signal("tiles_light_changed", button_pressed)


func _on_MouseStrength_value_changed(value: float) -> void:
	emit_signal("mouse_strength_changed", value)


func _on_TilesStrength_value_changed(value: float) -> void:
	emit_signal("tiles_strength_changed", value)


func _on_WindowOnTop_toggled(button_pressed: bool) -> void:
	OS.set_window_always_on_top(button_pressed)


func _on_GetModifiedTime_timeout() -> void:
	for i in len(curr_files):
		var curr_file: String = curr_files[i]
		var new_modified_time := file.get_modified_time(curr_file)
		if curr_file in modified_times and \
				modified_times[curr_file] != new_modified_time:
			if tiles_texture.texture is AnimatedTexture:
				tiles_texture.texture.set_frame_texture(
						i, get_texture(curr_file))
			else:
				var updated_texture := get_texture(curr_file)
				tiles_texture.texture = updated_texture
				emit_signal("file_changed", updated_texture)
		modified_times[curr_file] = new_modified_time


func _on_CellSizeX_number_changed(number: int) -> void:
	cell_size.x = number
	emit_signal("cell_size_changed", cell_size)


func _on_CellSizeY_number_changed(number: int) -> void:
	cell_size.y = number
	emit_signal("cell_size_changed", cell_size)


func _on_SubtileSizeX_number_changed(number: int) -> void:
	subtile_size.x = number
	emit_signal("subtile_size_changed", subtile_size)


func _on_SubtileSizeY_number_changed(number: int) -> void:
	subtile_size.y = number
	emit_signal("subtile_size_changed", subtile_size)


func _on_FPS_number_changed(number: int) -> void:
	tiles_texture.texture.fps = number
	curr_fps = number


func _on_ToggleVisibility_pressed() -> void:
	controls.visible = not controls.visible
	if controls.visible:
		toggle_visibility.icon = Visible
	else:
		toggle_visibility.icon = Hidden


func _on_PresetsTemp_pressed() -> void:
	load_texture_path(temp)
	cell_size_x.num = 24
	cell_size_y.num = 24
	subtile_size_x.num = 24
	subtile_size_y.num = 24


func _on_PresetsThick_pressed() -> void:
	load_texture_path(thick)
	cell_size_x.num = 64
	cell_size_y.num = 64
	subtile_size_x.num = 64
	subtile_size_y.num = 88


func _on_PresetsAnim_pressed() -> void:
	load_animated_texture_paths(anim)
	cell_size_x.num = 48
	cell_size_y.num = 48
	subtile_size_x.num = 48
	subtile_size_y.num = 48


func _on_DownloadTemp_pressed() -> void:
	download_file = "temp"
	save_file.popup_centered()


func _on_DownloadThick_pressed() -> void:
	download_file = "thick"
	save_file.popup_centered()


func _on_DownloadAnim_pressed() -> void:
	download_file = "anim"
	save_file.popup_centered()


func _on_SaveFile_dir_selected(dir: String) -> void:
	var d := Directory.new()
	match download_file:
		"temp":
			var new_filepath := dir.plus_file(temp.get_file())
			d.copy(temp, new_filepath)
			load_texture_path(new_filepath)
			cell_size_x.num = 24
			cell_size_y.num = 24
			subtile_size_x.num = 24
			subtile_size_y.num = 24
		"thick":
			var new_filepath := dir.plus_file(thick.get_file())
			d.copy(thick, new_filepath)
			load_texture_path(new_filepath)
			cell_size_x.num = 64
			cell_size_y.num = 64
			subtile_size_x.num = 64
			subtile_size_y.num = 88
		"anim":
			var new_filepaths := []
			for file in anim:
				var new_filepath := dir.plus_file(file.get_file())
				d.copy(file, new_filepath)
				new_filepaths.append(new_filepath)
			load_animated_texture_paths(new_filepaths)
			cell_size_x.num = 48
			cell_size_y.num = 48
			subtile_size_x.num = 48
			subtile_size_y.num = 48


func _on_AutotileTester_highlight_tile(coord: Vector2) -> void:
	if highlight_tile == coord:
		return
	highlight_tile = coord
	update()


func _draw() -> void:
	if highlight_tile.x < 0 or highlight_tile.y < 0:
		return
	var topleft: Vector2 = tiles_texture.rect_global_position - \
			Vector2(real_size.x, 0)
	var rect := Rect2(topleft + highlight_tile * texture_cell_size,
			texture_cell_size)
	draw_rect(rect, Color(0.6, 0.1, 0.9, 0.3))
	draw_rect(rect, Color.purple, false)
