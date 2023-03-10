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

func clone_array_type(array, source):
	var type = source.get_typed_builtin()
	var class_n = source.get_typed_class_name()
	var script = source.get_typed_script()
	return Array(array, type, class_n, script)

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
	# workaround for arrays apparently being readonly to EditorPlugins
	# basically just reassign the collection back and forth
	var is_typed = stored_collection.is_typed()
	if stored_collection.is_read_only():
		var arr = []
		if stored_collection.is_empty():
			arr = [ value ] # create first entry like so, because apparently cant access with index on empty array
		else:
			arr = [] + stored_collection
			# fix index number on arrays
			# bit of a hack because for some reason arrays set one too small key index, but correct key index if they have dictionaires as members
			# (that is because when array of dictionaries is opened via the btn, it calls this function, and sets the correct index that way)
			# so if dictionary member, the array key index is correct, so rather just set the index instead of appending
			if typeof(value) == TYPE_DICTIONARY: # assuming other types are not problematic, if so, look at the index value calc first imo.
				arr[key] = value
			else:
				arr.append(value)
		if is_typed:
			stored_collection = clone_array_type(arr, stored_collection)
		else:
			stored_collection = arr
	else:
		if (is_typed):
			var arr_t = stored_collection.get_typed_builtin()
			if typeof(value) != arr_t:
				# try to cast the value to the array type
				# needed because Slider inherited controls have value as float,
				# so otherwise typed arrays dont like it, like trying to enter float to int array
				# AFAIK the value is still assigned and cast automatically but engine complains if a incompatible value is inserted via GUI
				# (should work usually, as changing type is disabled for typed arrays
				# can fail if somehow user inserts value that cannot be cast.)
				stored_collection[key] = cast_to(value, arr_t)
		else:
			stored_collection[key] = value
	emit_signal("value_changed", stored_collection)

func _on_property_control_type_changed(type, control, container, is_key = false):
	var key = get_container_index(container)
	# check just in case, even if have removed all other items in the menu
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
