@tool
extends "res://addons/dictionary_inspector/elements/packed_array_property_editor.gd"

var keys_by_index := []
var last_type_k := TYPE_STRING


func add_all_items(collection):
	keys_by_index = collection.keys()
	var i := 0
	for k in collection:
		last_type_v = typeof(collection[k])
		last_type_k = typeof(k)
		add_child(create_item_container(i))
		i += 1


func display_key_on_label(value, label):
	if value is Color:
		label.text = "██" + value.to_html() + "██"
		label.self_modulate = value

	else:
		label.text = str(value)
		label.self_modulate = Color.WHITE


func create_item_container(index_in_collection):
	var c = init_prop_container.duplicate()
	var k = keys_by_index[index_in_collection]
	c.add_child(DictionaryInspectorArrayIndex.new(index_in_collection))
	c.get_child(0).connect("drop_received", _on_item_moved.bind(c))

	var label = Label.new()
	display_key_on_label(k, label)

	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)

	var edit_button = Button.new()
	edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	edit_button.tooltip_text = "Toggle Key/Type Editing"
	edit_button.connect("pressed", toggle_property_editable.bind(c))
	c.add_child(edit_button)
	c.add_child(create_item_control_for_type(typeof(stored_collection[k]), stored_collection[k], c, false))

	return c


func toggle_property_editable(container):
	var children = container.get_children()
	var index = get_container_index(container)
	var k = keys_by_index[index]
	if children[1].visible:
		children[1].hide()

		container.add_child(create_type_switcher(typeof(k), container, true))
		container.add_child(create_item_control_for_type(typeof(k), k, container, true))
		container.add_child(create_type_switcher(typeof(stored_collection[k]), container, false))

		# Move button and value editor to front
		container.move_child(children[2], 5)
		container.move_child(children[3], 6)

	else:
		display_key_on_label(k, children[1])
		children[1].show()
		children[2].queue_free()
		children[3].queue_free()
		children[5].queue_free()

func update_variant(key, value, is_rename = false):
	if is_rename:
		if (typeof(value) != typeof(key) || value != key):
			var new_collection = {}
			var found_at_index = keys_by_index.find(key)
			keys_by_index[found_at_index] = value
			stored_collection[value] = stored_collection[key]
			for x in keys_by_index:
				new_collection[x] = stored_collection[x]

			stored_collection = new_collection
			keys_by_index = stored_collection.keys()

	else:
			stored_collection[key] = value

	emit_signal("value_changed", stored_collection)


func _on_add_button_pressed():
	if last_type_k == TYPE_BOOL:
		last_type_k = TYPE_INT

	var new_key = get_default_for_type(last_type_k, true)
	var new_value = get_default_for_type(last_type_v)

	if stored_collection.is_empty():
		stored_collection = { new_key: new_value }
	else:
		stored_collection[new_key] = new_value
	keys_by_index = stored_collection.keys()

	var new_node = create_item_container(keys_by_index.size() - 1)
	add_child(new_node)
	move_child(new_node, get_child_count() - 1)
	emit_signal("value_changed", stored_collection)


func _on_property_control_value_changed(value, control, container, is_rename = false):
	var key = keys_by_index[get_container_index(container)]
	update_variant(key, value, is_rename)


func _on_property_control_type_changed(type, control, container, is_key = false):
	var key = keys_by_index[get_container_index(container)]
	if type == 0:
		_on_item_deleted(container)
		return

	var value = get_default_for_type(type, is_key)
	update_variant(key, value, is_key)
	var new_node = create_item_control_for_type(type, value, container, is_key)
	container.add_child(new_node)
	if is_key:
		last_type_k = type
		container.get_child(3).free()
		container.move_child(new_node, 3)

	else:
		last_type_v = type
		container.get_child(6).free()
		container.move_child(new_node, 6)


func _on_item_deleted(control):
	keys_by_index = stored_collection.keys()
	stored_collection.erase(keys_by_index[get_container_index(control)])
	control.queue_free()
	emit_signal("value_changed", stored_collection)


func _on_item_moved(from_container, to_container):
	var to_index = get_container_index(to_container)
	var from_index = get_container_index(from_container)
	keys_by_index.insert(to_index, keys_by_index.pop_at(from_index))

	var new_collection = {}
	move_child(from_container, to_index + 1)
	var i = 0
	for x in get_children():
		if x is HBoxContainer && x.get_child(0) is DictionaryInspectorArrayIndex:
			new_collection[keys_by_index[i]] = stored_collection[keys_by_index[i]]
			x.get_child(0).value = i
			i += 1
	
	emit_signal("value_changed", new_collection)
