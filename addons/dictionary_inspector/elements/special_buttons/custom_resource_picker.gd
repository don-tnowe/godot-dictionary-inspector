@tool
extends EditorResourcePicker

const setting_name = "addons/dictionary_inspector/resource_types"

@onready var button : Button = get_child(1)

var plugin


func _init(resource, plugin):
	editable = true
	toggle_mode = false
	edited_resource = resource
	self.plugin = plugin


func _ready():
	base_type = get_resource_base_type(edited_resource)


func get_resource_base_type(resource):
	if resource == null:
		return "Resource"
	
	var type = resource.get_class()
	if type == "Resource":
		# Custom classes return the base type,
		# so we need to get the script
		var script_path = resource.get_script().resource_path
		var dir = plugin.get_editor_interface()\
			.get_resource_filesystem()\
			.get_filesystem_path(script_path.get_base_dir())
		var index_in_dir = dir.find_file_index(script_path.get_file())
		type = dir.get_file_script_class_extends(index_in_dir)

		if type == "Resource":
			type = dir.get_file_script_class_name(index_in_dir)

		if type == "":
			var source = resource.get_script().source_code
			var found_extends = source.find("extends ") + 8
			type = source.substr(found_extends, source.find("\n", found_extends + 1) - found_extends)
	
	var parent = ClassDB.get_parent_class(type)
	if type == "":
		return "Resource"

	elif parent in [
		"Texture2D", "AudioStream", "PrimitiveMesh",
		"Shape3D", "Shape2D", "Script", "StyleBox",
	]:
		return parent

	elif ClassDB.is_parent_class(type, "InputEvent"):
		# Not always a direct child.
		return "InputEvent"

	else:
		return type


# TODO: implement saving of selected types to reload them later
# func _ready():
#   base_type = get_saved_type()


func _set_create_options(menu):
	if !menu.index_pressed.is_connected(_the_cooler_handle_menu_selected):
		menu.index_pressed.connect(_the_cooler_handle_menu_selected)

	var icon
	var i = 0
	for x in get_allowed_types():
		if has_theme_icon(x, "EditorIcons"):
			icon = get_theme_icon(x, "EditorIcons")

		else:
			icon = null

		menu.add_icon_item(icon, "New " + x, i + 100)
		i += 1
	
	menu.add_separator()
	menu.add_icon_item(get_theme_icon("Variant", "EditorIcons"), "Change Collection's Resource type", 90001)
	menu.add_icon_item(get_theme_icon("Object", "EditorIcons"), "Reset Base Type", 90002)
	menu.add_separator()


func _handle_menu_selected(id):
	if id == 90001:
		for x in get_children():
			x.hide()
		
		var edit = LineEdit.new()
		add_child(edit)
		edit.placeholder_text = "Enter class name..."
		edit.text_submitted.connect(_on_classname_submitted.bind(edit))
		edit.grab_focus()
		edit.size_flags_horizontal = SIZE_EXPAND_FILL

	elif id == 90002:
		_on_classname_submitted("Resource")
	
	elif id >= 100 && id < get_allowed_types().size() + 100:
		var new_res = ClassDB.instantiate(get_allowed_types()[id - 100])
		emit_signal("resource_changed", new_res)
		edited_resource = new_res

	return false


func _the_cooler_handle_menu_selected(id):
	if id == 7:
		if edited_resource is Script:
			plugin.get_editor_interface().edit_script.call_deferred(edited_resource)

		else:
			plugin.get_editor_interface().edit_resource.call_deferred(edited_resource)

	return false


# func get_saved_type():
#   if !ProjectSettings.has_setting(setting_name):
#     return
	
#   var dict = ProjectSettings.get_setting(setting_name)
#   return dict.get(path_to_property, "Resource")


func _on_classname_submitted(new_text, node = null):
	if is_instance_valid(node):
		node.queue_free()

	for x in get_children():
		x.show()
	
	if !ClassDB.class_exists(new_text):
		new_text = "Resource"
	
	var property_boxes = get_node("../..").get_children()
	for x in property_boxes:
		for y in x.get_children():
			if y is EditorResourcePicker:
				y.set_base_type(new_text)
	
	# TODO: allow creation of new resources of changed type
	# If Base Type is changed, can't create new instances
	if new_text != "Resource":
		_handle_menu_selected(0)

	# else:
	# 	get_child(0).grab_focus()

	# var setting_dict = ProjectSettings.get_setting(setting_name)
	# setting_dict[path_to_property] = new_text
	# ProjectSettings.set_setting(setting_name, new_text)  
