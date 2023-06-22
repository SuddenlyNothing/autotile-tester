tool
extends HBoxContainer

signal num_changed

export(String) var label_text setget set_label_text

onready var line_edit := $LineEdit
onready var curr_num := int(line_edit.text)


func set_label_text(val: String) -> void:
	label_text = val
	$Label.text = val


func _on_Increase_pressed() -> void:
	line_edit.text = str(line_edit.text.to_int() + 1)
	emit_signal("num_changed")


func _on_Decrease_pressed() -> void:
	line_edit.text = str(line_edit.text.to_int() - 1)
	emit_signal("num_changed")


func _on_LineEdit_text_changed(new_text: String) -> void:
	var new_num := int(new_text)
	if new_num != curr_num:
		curr_num = new_num
		emit_signal("num_changed")


func _on_LineEdit_text_entered(new_text: String) -> void:
	line_edit.text = str(int(new_text))
	line_edit.caret_position = len(line_edit.text)
