@tool
extends "res://addons/dictionary_inspector/elements/packed_array_property_editor.gd"

var header_node


func add_all_items(collection):
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
	var c = init_prop_container.duplicate()
	var index = DictionaryInspectorArrayIndex.new(index_in_collection)
	index.connect("drop_received", _on_item_moved.bind(c))
	c.add_child(index)
	c.add_child(create_type_switcher(typeof(stored_collection[index_in_collection]), c, false))
	c.add_child(create_item_control_for_type(typeof(stored_collection[index_in_collection]), stored_collection[index_in_collection], c, false))

	return c


func _on_property_control_type_changed(type, control, container, is_key = false):
	var key = get_container_index(container)
	if type == 0:
		_on_item_deleted(control)
		return
	
	var value = get_default_for_type(type)
	var new_editor = create_item_control_for_type(type, value, container, is_key)
	control.get_parent().get_child(control.get_position_in_parent() + 1).free()
	control.get_parent().add_child_below_node(control, new_editor)
	update_variant(key, value, false)
	last_type_v = type
