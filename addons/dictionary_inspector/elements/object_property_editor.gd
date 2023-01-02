@tool
extends "res://addons/dictionary_inspector/elements/base_property_editor.gd"


var all_properties := []


func add_all_items(collection):
	all_properties.clear()

	var prop_list = collection.get_property_list()
	var cur_name
	var i := -1
	for x in prop_list:
		if x["usage"] & PROPERTY_USAGE_EDITOR == 0:
			continue

		i += 1
		if i < 3: continue  # First 3 are Resource props.
		cur_name = x["name"]
		all_properties.append(cur_name)
		add_child(create_item_container(i - 3))
	
	all_properties.append("resource_name")
	add_child(create_item_container(i - 2))


func create_add_button():
	var box = HBoxContainer.new()
	var color_rect = ColorRect.new()
	color_rect.color = parent_stylebox.border_color
	color_rect.size_flags_horizontal = SIZE_EXPAND_FILL

	var icon = TextureRect.new()
	box.add_child(icon)
	box.add_theme_constant_override("separation", 0)
	icon.texture = get_theme_icon(stored_collection.get_class(), "EditorIcons")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	box.add_child(Label.new())
	box.get_child(1).text = stored_collection.resource_path.get_file()

	box.add_child(color_rect)

	var folderpath = LineEdit.new()
	box.add_child(folderpath)
	folderpath.editable = false
	folderpath.text = stored_collection.resource_path.get_base_dir()
	folderpath.size_flags_horizontal = SIZE_FILL

	icon.custom_minimum_size.x = icon.get_minimum_size().x + 8

	var result = MarginContainer.new()
	result.add_child(box)
	return result


func create_item_container(index_in_collection):
	var c = init_prop_container.duplicate()
	var key = all_properties[index_in_collection]
	var label = Label.new()
	label.text = key.capitalize()
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)
	c.add_child(create_item_control_for_type(typeof(stored_collection[key]), stored_collection[key], c, false))

	return c


func _on_property_control_value_changed(value, control, container, is_rename = false):
	update_variant(all_properties[get_container_index(container)], value, is_rename)
