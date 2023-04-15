@tool
extends "res://addons/dictionary_inspector/elements/base_property_editor.gd"


const array_to_element_type = {
	TYPE_PACKED_BYTE_ARRAY : TYPE_INT,
	TYPE_PACKED_STRING_ARRAY : TYPE_STRING,
	TYPE_PACKED_FLOAT32_ARRAY : TYPE_FLOAT,
	TYPE_PACKED_FLOAT64_ARRAY : TYPE_FLOAT,
	TYPE_PACKED_INT32_ARRAY : TYPE_INT,
	TYPE_PACKED_INT64_ARRAY : TYPE_INT,
	TYPE_PACKED_VECTOR2_ARRAY : TYPE_VECTOR2,
	TYPE_PACKED_VECTOR3_ARRAY : TYPE_VECTOR3,
	TYPE_PACKED_COLOR_ARRAY : TYPE_COLOR,
}

func get_array_type(arr):
	if typeof(arr) == TYPE_ARRAY && arr.is_typed():
		return arr.get_typed_builtin()
	else:
		return last_type_v

func add_all_items(collection):
	last_type_v = array_to_element_type.get(typeof(collection), TYPE_FLOAT)
	for i in collection.size():
		add_child(create_item_container(i))


func create_add_button():
	var button = Button.new()
	button.text = "Add Entry"
	button.icon = get_theme_icon("Add", "EditorIcons")
	button.size_flags_horizontal = SIZE_SHRINK_CENTER | SIZE_EXPAND
	button.custom_minimum_size.x = button.get_minimum_size().x + 64.0
	button.connect("pressed", _on_add_button_pressed)

	var result = MarginContainer.new()
	var color_rect = ColorRect.new()
	color_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	color_rect.color = parent_stylebox.border_color
	result.add_child(color_rect)
	result.add_child(button)
	return result


func create_item_container(index_in_collection):
	var c = init_prop_container.duplicate()
	c.add_child(DictionaryInspectorArrayIndex.new(index_in_collection))
	c.get_child(0).connect("drop_received", _on_item_moved.bind(c), CONNECT_DEFERRED)

	var type = get_array_type(stored_collection)
	c.add_child(create_item_control_for_type(type, stored_collection[index_in_collection], c, false))

	var delete_button = Button.new()
	delete_button.icon = get_theme_icon("Remove", "EditorIcons")
	delete_button.connect("pressed", _on_item_deleted.bind(c), CONNECT_DEFERRED)
	c.add_child(delete_button)

	return c


func _on_add_button_pressed():
	var type = get_array_type(stored_collection)
	var new_value = get_default_for_type(type)
	if stored_collection.size() > 0 && (
		last_type_v == TYPE_OBJECT || stored_collection[-1] is Object
	):
		new_value = stored_collection[-1].duplicate()

	stored_collection.append(new_value)
	update_variant(stored_collection.size() - 1, new_value, false)

	var new_node = create_item_container(stored_collection.size() - 1)
	add_child(new_node)
	emit_signal("value_changed", stored_collection)


func _on_item_deleted(control):
	stored_collection.remove_at(get_container_index(control))
	emit_signal("value_changed", stored_collection)
	display(stored_collection, plugin)


func _on_item_moved(from_container, to_container):
	var to_index = get_container_index(to_container)
	var from_index = get_container_index(from_container)
	var old_value = stored_collection[from_index]
	stored_collection.remove_at(from_index)
	stored_collection.insert(to_index, old_value)

	move_child(from_container, to_index + 1)
	var i = 0
	for x in get_children():
		if x is HBoxContainer && x.get_child(0) is DictionaryInspectorArrayIndex:
			x.get_child(0).value = i
			i += 1
	
	emit_signal("value_changed", stored_collection)
