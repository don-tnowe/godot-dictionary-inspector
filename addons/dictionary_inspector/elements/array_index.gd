tool
class_name EditorArrayIndex
extends Button

signal drop_received(from_index)

var value := 0


func _init(position):
	value = position
	text = str(position)
	rect_min_size.x = 24


func get_drag_data(position):
	var preview = get_parent().duplicate()
	set_drag_preview(preview)
	if preview.get_child(2) is TypeOptionButton:
		preview.get_child(2).call_deferred("_on_item_selected", get_parent().get_child(2).selected)

	return {"array_move_from": value}


func can_drop_data(position, data):
	return data.has("array_move_from")


func drop_data(position, data):
	emit_signal("drop_received", data["array_move_from"])
