extends Control

signal file_changed(texture)
signal mouse_light_changed(is_on)
signal mouse_strength_changed(value)
signal tiles_light_changed(is_on)
signal tiles_strength_changed(value)
signal window_on_top_changed(is_on_top)
signal cell_size_changed(cell_size)
signal subtile_size_changed(subtile_size)

var file := File.new()
export(String, FILE, "*.png") var curr_file
var modified_time := -1
var curr_fps := 10

export var cell_size := Vector2(24, 24)
export var subtile_size := Vector2(24, 24)

onready var file_dialog := $"%FileDialog"
onready var current_file := $"%CurrentFile"
onready var tiles_texture := $"%TilesTexture"
onready var accept_dialog := $"%AcceptDialog"
onready var fps: HBoxContainer = $"%FPS"


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


func load_animated_texture(paths: PoolStringArray) -> void:
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


func load_texture(path: String) -> void:
	fps.hide()
	if path.get_extension() != "png":
		accept_dialog.popup_centered()
		return
	curr_file = path
	current_file.text = path.get_file()
	var texture := get_texture(path)
	modified_time = -1
	tiles_texture.texture = texture
	emit_signal("file_changed", texture)


func _on_files_dropped(files: PoolStringArray, screen: int) -> void:
	if files.size() == 1:
		load_texture(files[0])
	else:
		load_animated_texture(files)


func _on_FileDialog_files_selected(paths: PoolStringArray) -> void:
	if paths.size() == 1:
		load_texture(paths[0])
	else:
		load_animated_texture(paths)


func _on_FileDialog_file_selected(path: String) -> void:
	load_texture(path)


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
