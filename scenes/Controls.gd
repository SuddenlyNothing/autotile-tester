extends Control

signal file_changed(texture)
signal mouse_light_changed(is_on)
signal mouse_strength_changed(value)
signal tiles_light_changed(is_on)
signal tiles_strength_changed(value)
signal window_on_top_changed(is_on_top)

onready var file_dialog := $"%FileDialog"
onready var current_file := $"%CurrentFile"
onready var tiles_texture := $"%TilesTexture"
onready var accept_dialog := $"%AcceptDialog"


func _ready() -> void:
	get_tree().connect("files_dropped", self, "_on_files_dropped")


func _on_files_dropped(files: PoolStringArray, screen: int) -> void:
	_on_FileDialog_file_selected(files[0])


func _on_FileDialog_file_selected(path: String) -> void:
	if path.get_extension() != "png":
		accept_dialog.popup_centered()
		return
	current_file.text = path.get_file()
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		print("uh oh!")
	var texture := ImageTexture.new()
	texture.create_from_image(image, 0)
	tiles_texture.texture = texture
	emit_signal("file_changed", texture)


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
