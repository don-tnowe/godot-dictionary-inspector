tool
class_name ObjectPropertyEditor
extends Button

signal value_changed(new_value)

export var value : Resource setget _set_value

var last_dropped_data


func _set_value(v):
	value = v
	text = value.resource_name
	if text == "": 
		text = value.resource_path.get_file().get_basename()

	if text == "":
		text = "Resource"
	
	if v is Texture:
		expand_icon = true
		icon = v
		rect_min_size.y = 48.0

	else:
		icon = null
		rect_min_size.y = 0.0

	emit_signal("value_changed", value)


func can_drop_data(position, data):
	return data.has("files")


func drop_data(position, data):
	if data.has("files"):
		_set_value(load(data["files"][0]))
	
	if data.has("resource"):
		_set_value(data["resource"])

	last_dropped_data = data


func get_drag_data(position):
	return {
		"from": self,
		"files": [value.resource_path],
	}
