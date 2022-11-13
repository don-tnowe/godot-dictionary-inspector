tool
class_name ArrayPropertyEditor
extends DictPropertyEditor

var header_node


func display(dcit, plugin):
	.display(dcit, plugin)
	size_flags_stretch_ratio = 1.0
	rect_size.x = 0
	hide()
	show()  # to update rect again


func can_drop_data(position, data):
	return data.has("files") || data.has("resource")


func drop_data(position, data):
	last_type_v = TYPE_OBJECT
	if data.has("resource"):
		_on_add_button_pressed()
		update_variant(dict.size() - 1, data["resource"], false)
		get_child(get_child_count() - 1).get_child(2).set_value(data["resource"])
	
	for x in data["files"]:
		_on_add_button_pressed()
		update_variant(dict.size() - 1, load(x), false)
		get_child(get_child_count() - 1).get_child(2).drop_data({
			"from": data["from"],
		})


func create_property_container(k):
	var c = init_prop_container.duplicate()
	var index = EditorArrayIndex.new(k)
	index.connect("drop_received", self, "_on_item_moved", [k])
	c.add_child(index)
	c.add_child(create_type_switcher(typeof(dict[k]), k, false))
	c.add_child(create_property_control_for_type(typeof(dict[k]), dict[k], k, false))

	return c


func update_variant(index, value, is_rename):
	dict[index] = value
	emit_signal("value_changed", dict)


func _on_add_button_pressed():
	var new_value = default_per_class[last_type_v]
	if dict.size() > 0 && (last_type_v == TYPE_OBJECT || dict[-1] is Object):
		new_value = dict[-1].duplicate()

	dict.append(new_value)
	update_variant(dict.size() - 1, new_value, false)

	var new_node = create_property_container(dict.size() - 1)
	add_child(new_node)
	move_child(new_node, get_child_count() - 1)


func _on_property_control_type_changed(type, control, key, is_key = false):
	if type == 0:
		_on_property_deleted(key, control)
		return
	
	var value = default_per_class[type]
	var new_editor = create_property_control_for_type(type, value, key, is_key)
	control.get_parent().get_child(control.get_position_in_parent() + 1).free()
	control.get_parent().add_child_below_node(control, new_editor)
	update_variant(key, value, false)
	last_type_v = type


func _on_property_deleted(key, control):
	dict.remove(key)
	control.get_parent().queue_free()
	emit_signal("value_changed", dict)


func _on_item_moved(from, to):
	var old_value = dict[from]
	dict.remove(from)
	dict.insert(to, old_value)

	# Too lazy right now to make proper movement, plus this is more reliable
	display(dict, plugin)
