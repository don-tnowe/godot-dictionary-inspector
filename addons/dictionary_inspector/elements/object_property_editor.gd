tool
class_name ObjectPropertyEditor
extends BaseCollectionPropertyEditor


var all_properties := []


func add_all_properties(collection):
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
		add_child(create_property_container(i - 3))
	
	all_properties.append("resource_name")
	add_child(create_property_container(i - 2))


func create_add_button():
	var result = HBoxContainer.new()
	var color_rect = ColorRect.new()
	color_rect.color = get_node("../../ColorRect").color
	color_rect.show_behind_parent = true
	color_rect.set_anchors_and_margins_preset(PRESET_WIDE)

	var icon = TextureRect.new()
	result.add_child(icon)
	icon.texture = get_icon(stored_collection.get_class(), "EditorIcons")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.add_child(color_rect)
	result.add_child(Label.new())
	result.get_child(1).text = stored_collection.resource_path.get_file()

	var folderpath = Label.new()
	result.add_child(folderpath)
	folderpath.text = stored_collection.resource_path.get_base_dir()
	folderpath.add_child(color_rect.duplicate())
	folderpath.size_flags_horizontal = SIZE_EXPAND_FILL
	folderpath.clip_text = true

	icon.rect_min_size.x = icon.get_minimum_size().x + 8

	return result


func create_property_container(index_in_collection):
	var c = init_prop_container.duplicate()
	var key = all_properties[index_in_collection]
	var label = Label.new()
	label.text = key.capitalize()
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)
	c.add_child(create_property_control_for_type(typeof(stored_collection[key]), stored_collection[key], c, false))

	return c


func _on_property_control_value_changed(value, control, container, is_rename = false):
	update_variant(all_properties[get_container_index(container)], value, is_rename)
