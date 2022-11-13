tool
class_name PackedArrayPropertyEditor
extends ArrayPropertyEditor


const array_to_element_type = {
	TYPE_RAW_ARRAY : TYPE_INT,
	TYPE_INT_ARRAY : TYPE_INT,
	TYPE_REAL_ARRAY : TYPE_REAL,
	TYPE_STRING_ARRAY : TYPE_STRING,
	TYPE_VECTOR2_ARRAY : TYPE_VECTOR2,
	TYPE_VECTOR3_ARRAY : TYPE_VECTOR3,
	TYPE_COLOR_ARRAY : TYPE_COLOR,
}


func display(dict, plugin):
	last_type_v = array_to_element_type[typeof(dict)]
	.display(dict, plugin)


func can_drop_data(position, data):
	return false


func create_property_container(k):
	var c = init_prop_container.duplicate()
	c.add_child(EditorArrayIndex.new(k))
	c.get_child(0).connect("drop_received", self, "_on_item_moved", [k])
	c.add_child(create_property_control_for_type(last_type_v, dict[k], k, false))
	var delete_button = Button.new()
	delete_button.text = "X"
	delete_button.connect("pressed", self, "_on_property_deleted", [k, c])
	c.add_child(delete_button)

	return c
