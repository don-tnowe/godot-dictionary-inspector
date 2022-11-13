tool
class_name ArrayPropertyEditor
extends DictPropertyEditor


var header_node


func can_drop_data(position, data):
	return data.has("files")


func drop_data(position, data):
	last_type_v = TYPE_OBJECT
	for x in data["files"]:
		_on_add_button_pressed()
		update_variant(dict.size() - 1, load(x), false)
		get_child(get_child_count() - 2).get_child(3).value = load(x)


func create_header():
	var result = MarginContainer.new()

	result.add_child(create_color_rect())
	result.mouse_filter = MOUSE_FILTER_IGNORE
	
	var inner_container = VBoxContainer.new()
	header_node = Button.new()
	header_node.mouse_filter = MOUSE_FILTER_IGNORE
	update_header()
	header_node.size_flags_vertical = SIZE_EXPAND_FILL
	header_node.size_flags_horizontal = SIZE_SHRINK_CENTER
	result.rect_min_size.x = result.get_minimum_size().x + 64.0

	inner_container.add_child(header_node)
	inner_container.add_child(create_add_button())
	result.add_child(inner_container)
	return result


func create_property_container(k):
	var c = init_prop_container.duplicate()
	c.add_child(create_color_rect())
	c.add_child(Button.new())
	c.get_child(1).text = str(k)
	c.get_child(1).rect_min_size.x = 24
	c.add_child(create_type_switcher(typeof(dict[k]), k, false))
	c.add_child(create_property_control_for_type(typeof(dict[k]), dict[k], k, false))
	c.add_child(create_delete_button(k))
	c.add_child(create_color_rect())

	return c


func update_variant(index, value, is_rename):
	dict[index] = value
	emit_signal("value_changed", dict)


func update_header():
	header_node.text = "Array (size " + str(dict.size()) + ")"


func _on_add_button_pressed():
	var new_value = default_per_class[last_type_v]
	if dict.size() > 0 && (last_type_v == TYPE_OBJECT || dict[-1] is Object):
		new_value = dict[-1].duplicate()

	dict.append(new_value)
	update_variant(dict.size() - 1, new_value, false)
	update_header()

	var new_node = create_property_container(dict.size() - 1)
	add_child(new_node)
	move_child(new_node, get_child_count() - 2)


func _on_property_control_type_changed(type, control, key, is_key = false):
	var value = default_per_class[type]
	var new_editor = create_property_control_for_type(type, value, key, is_key)
	control.get_parent().get_child(control.get_position_in_parent() + 1).free()
	control.get_parent().add_child_below_node(control, new_editor)
	update_variant(key, value, false)
	last_type_v = type


func _on_property_deleted(key, control):
	dict.remove(key)
	control.get_parent().queue_free()
	update_header()
	emit_signal("value_changed", dict)
