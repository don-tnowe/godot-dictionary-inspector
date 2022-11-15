tool
class_name EditorArrayIndex
extends Button

signal drop_received(from_container)

var value := 0 setget _set_value


func _set_value(v):
	value = v
	text = str(v)


func _init(position):
	_set_value(position)
	rect_min_size.x = 24


func get_drag_data(position):
	var preview = get_parent().duplicate()
	set_drag_preview(preview)
	return {"array_move_from": get_parent()}


func can_drop_data(position, data):
	return data.has("array_move_from")


func drop_data(position, data):
	emit_signal("drop_received", data["array_move_from"])
