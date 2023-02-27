@tool
extends "res://addons/dictionary_inspector/elements/base_property_editor.gd"


var all_properties := [] 
var last_group_item_container
var last_group_prefix = ""
var last_category_item_container

func add_all_items(collection):
	last_group_item_container = null
	all_properties.clear()

	var prop_list = collection.get_property_list()
	var cur_name
	var i := -1
	theme = Theme.new()

	for name in ["normal","hover","pressed","disabled","focus"] :
		var style_box : StyleBoxFlat = get_theme_stylebox(name, "Button").duplicate()
		style_box.set_content_margin(SIDE_BOTTOM,0)
		style_box.set_content_margin(SIDE_TOP,0)
		style_box.set_corner_radius_all(0)
		theme.set_stylebox(name, "Button", style_box)

	for color_name in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color" ,"font_disabled_color"]:
		theme.set_color(color_name,"Button", Color.WHITE)

	for color_name in ["icon_normal_color", "icon_pressed_color", "icon_hover_color", "icon_focus_color", "icon_hover_pressed_color" ,"icon_disabled_color"]:
		theme.set_color(color_name,"Button", Color.GRAY)
	var group_font = FontVariation.new()
	group_font.variation_embolden = 0.3
	theme.set_font("font","Button",group_font)

	var label_font = FontVariation.new()
	label_font.variation_embolden = -0.3
	theme.set_font("font","Label",label_font)

	theme.set_constant("separation","VBoxContainer",0)
	
	for x in prop_list:
		print(x)
		var usage = x.usage

		if usage & PROPERTY_USAGE_EDITOR != 0:
			cur_name = x["name"]
			all_properties.append(cur_name)
			create_item_container(i)

		if usage & PROPERTY_USAGE_GROUP != 0:
			create_group_container(x)
		
		if usage & PROPERTY_USAGE_CATEGORY != 0:
			create_category_container()
	check_for_empty_last_group()



func create_add_button():
	var box = HBoxContainer.new()

	var icon = TextureRect.new()
	box.add_child(icon)
	box.add_theme_constant_override("separation", 0)
	icon.texture = get_theme_icon(stored_collection.get_class(), "EditorIcons")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size.x = icon.get_minimum_size().x + 16

	var color_rect = ColorRect.new()
	color_rect.color = parent_stylebox.border_color
	color_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_child(color_rect)

	var result = MarginContainer.new()
	result.add_child(box)
	return result


func create_item_container(index_in_collection):
	var c = init_prop_container.duplicate()
	var key = all_properties[index_in_collection]
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20,0)
	c.add_child(spacer)
	var label = Label.new()
	label.text = "\t" + key.trim_prefix(last_group_prefix).capitalize()
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)
	c.add_child(create_item_control_for_type(typeof(stored_collection[key]), stored_collection[key], c, false))
	if last_group_item_container :
		last_group_item_container.add_child(c)
	elif last_category_item_container:
		last_category_item_container.add_child(c)
	else:
		add_child(c)
	return c

func create_group_container(group):
	check_for_empty_last_group()
	last_group_prefix = group.hint_string
	
	if group.name:
		var group_container = VBoxContainer.new()
		add_child(group_container)

		var group_header_button = Button.new()
		group_header_button.text = group.name
		group_header_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		group_header_button.toggle_mode = true
		group_container.add_child(group_header_button)
		
		
		var group_item_container = VBoxContainer.new()
		last_group_item_container = group_item_container
		group_container.add_child(group_item_container)
		group_header_button.toggled.connect(on_group_toggled.bind(group_item_container,group_header_button))
		on_group_toggled(false,group_item_container,group_header_button)
	else :
		last_group_item_container = null



func create_category_container():
	var category_container = VBoxContainer.new()
	add_child(category_container)
	move_child(category_container,1)
	last_category_item_container = category_container
	


func on_group_toggled(toggled,group_item_container,group_header_button):
	group_header_button.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")\
							if toggled else get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	group_item_container.visible = toggled

func _on_property_control_value_changed(value, control, container, is_rename = false):
	print(get_container_index(container))
	update_variant(all_properties[get_container_index(container)], value, is_rename)

func check_for_empty_last_group():
	if last_group_item_container and last_group_item_container.get_child_count() == 0 :
		last_group_item_container.get_parent().queue_free()
