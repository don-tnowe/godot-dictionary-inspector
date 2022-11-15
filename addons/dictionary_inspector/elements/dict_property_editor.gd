tool
class_name DictPropertyEditor
extends PackedArrayPropertyEditor

var last_type_k := TYPE_STRING


func add_all_properties(collection):
	for k in collection:
		last_type_v = typeof(collection[k])
		last_type_k = typeof(k)
		add_child(create_property_container(k))


func display_key_on_label(value, label):
	if value is Color:
		label.text = "██" + value.to_html() + "██"
		label.self_modulate = value

	else:
		label.text = str(value)
		label.self_modulate = Color.white


func create_property_container(k):
	var c = init_prop_container.duplicate()
	var label = Label.new()
	display_key_on_label(k, label)

	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)

	var edit_button = Button.new()
	edit_button.icon = get_icon("Edit", "EditorIcons")
	edit_button.hint_tooltip = "Toggle Key/Type Editing"
	edit_button.connect("pressed", self, "toggle_property_editable", [k, c])
	c.add_child(edit_button)
	c.add_child(create_property_control_for_type(typeof(stored_collection[k]), stored_collection[k], k, false))

	return c


func toggle_property_editable(k, container):
	var children = container.get_children()
	if children[0].visible:
		children[0].hide()
		container.add_child(create_type_switcher(typeof(k), k, true))
		container.add_child(create_property_control_for_type(typeof(k), k, k, true))
		container.add_child(create_type_switcher(typeof(stored_collection[k]), k, false))
		container.move_child(children[1], 4)
		container.move_child(children[2], 6)

	else:
		display_key_on_label(k, children[0])
		children[0].show()
		children[1].queue_free()
		children[2].queue_free()
		children[4].queue_free()


func update_variant(key, value, is_rename = false):
	if is_rename:
		if (typeof(value) != typeof(key) || value != key):
			stored_collection[value] = stored_collection[key]
			stored_collection.erase(key)
	
	else:
		stored_collection[key] = value
	
	emit_signal("value_changed", stored_collection)


func _on_add_button_pressed():
	if last_type_k == TYPE_BOOL:
		last_type_k = TYPE_INT

	var new_key = default_per_class[last_type_k]
	var new_value = default_per_class[last_type_v]
	while stored_collection.has(new_key):
		if last_type_k == TYPE_INT || last_type_k == TYPE_REAL:
			new_key += 1

		elif last_type_k == TYPE_STRING || last_type_k == TYPE_NODE_PATH:
			new_key += "2"
		
		elif last_type_k == TYPE_VECTOR2 || last_type_k == TYPE_VECTOR3:
			new_key.x += 1.0

		elif last_type_k == TYPE_COLOR:
			new_key = new_key.from_hsv(new_key.h + 0.01, new_key.s, new_key.v)

		else:
			return
	
	stored_collection[new_key] = new_value

	var new_node = create_property_container(new_key)
	add_child(new_node)
	move_child(new_node, get_child_count() - 1)
	emit_signal("value_changed", stored_collection)


func _on_property_control_value_changed(value, control, key, is_rename = false):
	if !is_rename:
		update_variant(key, value, is_rename)
		return

	var parent_children = control.get_parent().get_children()
	var old_value = stored_collection[key]
	update_variant(key, value, is_rename)
	connect_control(control, typeof(value), value, true)
	connect_control(parent_children[5], typeof(old_value), value, false)
	yield(get_tree(), "idle_frame")
	parent_children[1].replace_by(create_type_switcher(typeof(value), value, true))
	parent_children[1].free()
	parent_children[3].disconnect("pressed", self, "toggle_property_editable")
	parent_children[3].connect("pressed", self, "toggle_property_editable", [value, control.get_parent()])
	parent_children[4].replace_by(create_type_switcher(typeof(old_value), value, false))
	parent_children[4].free()


func _on_property_control_type_changed(type, control, key, is_key = false):
	if type == 0:
		_on_property_deleted(key, control)
		return

	var value = default_per_class[type]
	update_variant(key, value, is_key)
	var old_prop = control.get_parent()
	add_child_below_node(old_prop, create_property_container(value if is_key else key))
	old_prop.free()
	if is_key:
		last_type_k = type

	else:
		last_type_v = type


func _on_property_deleted(key, control):
	stored_collection.erase(key)
	control.get_parent().queue_free()
	emit_signal("value_changed", stored_collection)
