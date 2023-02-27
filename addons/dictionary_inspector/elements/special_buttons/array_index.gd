@tool
extends Button

signal drop_received(from_container)

var value := 0: set = _set_value


func _set_value(v):
	value = v
	text = str(v)


func _init(position):
	_set_value(position)
	custom_minimum_size.x = 24
	mouse_default_cursor_shape = Control.CURSOR_MOVE


func _get_drag_data(position):
	var preview = get_parent().duplicate(0)
	set_drag_preview(preview)
	return {"array_move_from": get_parent()}


func _can_drop_data(position, data):
	return data.has("array_move_from")


func _drop_data(position, data):
	emit_signal("drop_received", data["array_move_from"])
