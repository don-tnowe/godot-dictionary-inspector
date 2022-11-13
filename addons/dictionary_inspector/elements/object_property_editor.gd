tool
class_name ObjectPropertyEditor
extends Button

signal value_changed(new_value)

export var value : Resource setget _set_value


func _set_value(v):
	value = v
	value.resource_name
	if text == "": 
		text = value.resource_path.get_file().get_basename()

	if text == "":
		text = "Resource"

	emit_signal("value_changed", value)


func can_drop_data(position, data):
	return data.has("files")


func drop_data(position, data):
	_set_value(load(data["files"][0]))
