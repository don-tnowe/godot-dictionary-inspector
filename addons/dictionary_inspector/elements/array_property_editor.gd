@tool
extends "res://addons/dictionary_inspector/elements/packed_array_property_editor.gd"

var header_node


func add_all_items(collection):
	if !collection.is_empty():
		last_type_v = typeof(collection[-1])
		for i in collection.size():
			add_child(create_item_container(i))


func can_drop_data(position, data):
	return data.has("files") || data.has("resource")


func drop_data(position, data):
	last_type_v = TYPE_OBJECT
	if data.has("resource"):
		_on_add_button_pressed()
		update_variant(stored_collection.size() - 1, data["resource"], false)
	
	for x in data["files"]:
		_on_add_button_pressed()
		update_variant(stored_collection.size() - 1, load(x), false)

func create_item_container(index_in_collection):
	if !stored_collection.is_empty():
		var c = init_prop_container.duplicate()
		var index = DictionaryInspectorArrayIndex.new(index_in_collection)
		index.connect("drop_received", _on_item_moved.bind(c))
		c.add_child(index)
		c.add_child(create_type_switcher(typeof(stored_collection[index_in_collection]), c, false))
		c.add_child(create_item_control_for_type(typeof(stored_collection[index_in_collection]), stored_collection[index_in_collection], c, false))

		return c

func update_variant(key, value, is_rename = false):
	var is_typed = stored_collection.is_typed()
	# workaround for arrays apparently sometimes being readonly to EditorPlugins
	# basically just reassign the collection back and forth
	if stored_collection.is_read_only():
		var arr = [] + stored_collection
		# for some reason arrays set one too small key index, but correct key index if value is dictionary
		# so if dictionary member, the array key index is correct, so rather just set the index instead of appending
		if typeof(value) == TYPE_DICTIONARY:
			arr[key] = value
		else:
			arr.append(value)
		stored_collection = arr if !is_typed else Array(arr, stored_collection.get_typed_builtin(), stored_collection.get_typed_class_name(), stored_collection.get_typed_script())
	else:
		if (is_typed):
			var arr_t = stored_collection.get_typed_builtin()
			if typeof(value) != arr_t:
				# try to cast the value to the array type
				# needed when assigning to typed arrays, because for example Slider inherited controls 
				# have value as float and engine prints error (the value seems to be still inserted and automatically cast to type of array)
				stored_collection[key] = convert(value, arr_t)
		else:
			stored_collection[key] = value
	emit_signal("value_changed", stored_collection)

func _on_property_control_type_changed(type, control, container, is_key = false):
	var key = get_container_index(container)
	# check type just in case, even if have deactivated all other items in the menu
	if stored_collection.is_typed() && type != 0:
		type = stored_collection.get_typed_builtin()
		var i = control.get_type_dict_index(type)
		print("This is a typed Array of type ", control.typenames.keys()[i], " only!")
		control.select(i)
		control.text = ""
	else:
		if type == 0:
			_on_item_deleted(container)
			return
	
	var value = get_default_for_type(type)
	var new_editor = create_item_control_for_type(type, value, container, is_key)
	control.get_parent().get_child(control.get_index() + 1).free()
	control.add_sibling(new_editor)
	update_variant(key, value, false)
	last_type_v = type
