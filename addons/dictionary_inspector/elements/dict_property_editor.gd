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
	var item_container = init_prop_container.duplicate()
	var k = keys_by_index[index_in_collection]
	
	var index_indicator = DictionaryInspectorArrayIndex.new(index_in_collection)
	index_indicator.drop_received.connect(_on_item_moved.bind(item_container))
	
	
	var key_container = init_prop_container.duplicate()

	var label = Label.new()
	display_key_on_label(k, label)
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	key_container.add_child(label)

	var edit_button = Button.new()
	edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	edit_button.tooltip_text = "Toggle Key/Type Editing"
	edit_button.pressed.connect(toggle_property_editable.bind(item_container))
	key_container.add_child(edit_button)
	
	var value_container = init_prop_container.duplicate()
	value_container.add_child(create_item_control_for_type(typeof(stored_collection[k]), stored_collection[k], item_container, false))

	
	item_container.add_child(index_indicator)
	item_container.add_child(key_container)
	item_container.add_child(value_container)
	return item_container


func toggle_property_editable(container):	
	var key_container : HBoxContainer = container.get_child(1)
	var value_container : HBoxContainer = container.get_child(2)
	
	var key_container_children = key_container.get_children()
	var value_container_children = value_container.get_children()
	
	var index = get_container_index(container)
	var k = keys_by_index[index]
	
	if key_container_children[0].visible:
		key_container_children[0].hide()
		var delete_button
		key_container_children[0].add_sibling(create_item_control_for_type(typeof(k), k, container, true))
		key_container_children[0].add_sibling(create_type_switcher(typeof(k), container, true))
		var value_type_switcher = create_type_switcher(typeof(stored_collection[k]), container, false)
		value_container.add_child(value_type_switcher)
		value_container.move_child(value_type_switcher,0)
		var DeleteButton = init_delete_button.duplicate()
		DeleteButton.pressed.connect(_on_item_deleted.bind(container))
		value_container.add_child(DeleteButton)
	else:
		display_key_on_label(k, key_container_children[0])
		key_container_children[0].show()
		key_container_children[1].queue_free()
		key_container_children[2].queue_free()
		value_container_children[0].queue_free()
		value_container_children[value_container_children.size()-1].queue_free()
	

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

	value_changed.emit(stored_collection)


func _on_add_button_pressed():
	
	if last_type_k == TYPE_BOOL:
		last_type_k = TYPE_INT
	
	var new_key = get_default_for_type(last_type_k, true)
	var new_value = get_default_for_type(last_type_v)
	stored_collection[new_key] = new_value
	keys_by_index = stored_collection.keys()

	var new_node = create_item_container(keys_by_index.size() - 1)
	add_child(new_node)
	move_child(new_node, get_child_count() - 1)
	emit_signal("value_changed", stored_collection)


func _on_property_control_value_changed(value, control, container, is_rename = false):
	var key = keys_by_index[get_container_index(container)]
	update_variant(key, value, is_rename)


func _on_property_control_type_changed(type_index, control, container, is_key = false):
	var type = control.get_item_id(type_index)
	var key = keys_by_index[get_container_index(container)]
	if type == 0:
		_on_item_deleted(container)
		return

	var value = get_default_for_type(type, is_key)
	update_variant(key, value, is_key)
	var new_node = create_item_control_for_type(type, value, container, is_key)
	var node_to_replace
	if is_key:
		last_type_k = type
		node_to_replace = container.get_child(1).get_child(2)

	else:
		last_type_v = type
		node_to_replace = container.get_child(3).get_child(1)

	node_to_replace.add_sibling(new_node)
	node_to_replace.free()
	


func _on_item_deleted(control):
	stored_collection.erase(keys_by_index[get_container_index(control)])
	control.queue_free()
	keys_by_index = stored_collection.keys()
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
