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

export(String, FILE, "*.png") var curr_file

var file := File.new()
var modified_time := -1
var curr_fps := 10

var download_file := ""

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
	curr_file = paths[0]
	modified_time = -1
	for i in len(paths):
		var texture := get_texture(paths[i])
		anim_texture.set_frame_texture(i, texture)
	tiles_texture.texture = anim_texture
	emit_signal("file_changed", anim_texture)


func load_texture_path(path: String) -> void:
	if path.get_extension() != "png":
		accept_dialog.popup_centered()
		return
	fps.hide()
	curr_file = path
	current_file.text = path.get_file()
	var texture := get_texture(path)
	modified_time = -1
	tiles_texture.texture = texture
	emit_signal("file_changed", texture)


func load_texture(texture: Texture) -> void:
	pass


func _on_files_dropped(files: PoolStringArray, screen: int) -> void:
	if files.size() == 1:
		load_texture_path(files[0])
	else:
		load_animated_texture_paths(files)


func _on_FileDialog_files_selected(paths: PoolStringArray) -> void:
	if paths.size() == 1:
		load_texture_path(paths[0])
	else:
		load_animated_texture_paths(paths)


func _on_ChangeFile_pressed() -> void:
	file_dialog.popup()


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
	var new_modified_time := file.get_modified_time(curr_file)
	if modified_time >= 0 and new_modified_time != modified_time:
		var updated_texture := get_texture(curr_file)
		tiles_texture.texture = updated_texture
		emit_signal("file_changed", updated_texture)
	modified_time = new_modified_time


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
	save_file.popup()


func _on_DownloadThick_pressed() -> void:
	download_file = "thick"
	save_file.popup()


func _on_DownloadAnim_pressed() -> void:
	download_file = "anim"
	save_file.popup()


func _on_SaveFile_dir_selected(dir: String) -> void:
	var d := Directory.new()
	match download_file:
		"temp":
			d.copy(temp, dir.plus_file(temp.get_file()))
		"thick":
			d.copy(thick, dir.plus_file(thick.get_file()))
		"anim":
			for file in anim:
				d.copy(file, dir.plus_file(file.get_file()))
