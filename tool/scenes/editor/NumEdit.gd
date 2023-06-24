tool
extends HBoxContainer

signal number_changed(number)

export(int) var num := 24 setget set_num
export(int) var min_num := 1

var previous_number: int

onready var line_edit := $LineEdit
onready var curr_num := int(line_edit.text)


func _ready() -> void:
	if not Engine.editor_hint:
		previous_number = num
		line_edit.text = str(previous_number)


func set_num(val: int) -> void:
	num = val
	if line_edit:
		line_edit.text = str(val)
		if not Engine.editor_hint and previous_number != val:
			emit_signal("number_changed", val)
			previous_number = val


func _on_LineEdit_text_changed(new_text: String) -> void:
	var prev_caret_pos: int = line_edit.caret_position
	var new_num := max(min_num, int(new_text))
	line_edit.text = "" if new_text.empty() else str(new_num)
	if len(line_edit.text) < len(new_text):
		line_edit.caret_position = prev_caret_pos - 1
	else:
		line_edit.caret_position = prev_caret_pos
	if new_num != previous_number:
		emit_signal("number_changed", new_num)
		previous_number = new_num


func _on_Increase_pressed() -> void:
	previous_number += 1
	line_edit.text = str(previous_number)
	emit_signal("number_changed", previous_number)


func _on_Decrease_pressed() -> void:
	previous_number -= 1
	if previous_number < min_num:
		previous_number += 1
		return
	line_edit.text = str(previous_number)
	emit_signal("number_changed", previous_number)
