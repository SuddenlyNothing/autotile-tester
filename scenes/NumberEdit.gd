extends LineEdit

signal number_changed(number)

var previous_number: int


func _ready() -> void:
	previous_number = int(text)
	text = str(previous_number)


func _on_NumberEdit_text_changed(new_text: String) -> void:
	var prev_caret_pos := caret_position
	var new_num := int(new_text)
	text = str(new_num)
	if len(text) < len(new_text):
		caret_position = prev_caret_pos - 1
	else:
		caret_position = prev_caret_pos
	if new_num != previous_number:
		emit_signal("number_changed", new_num)
		previous_number = new_num
