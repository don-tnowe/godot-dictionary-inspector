class_name ObjectPropertyEditor
extends DictPropertyEditor

var stored_resource


func display(dict, plugin):
	self.plugin = plugin
	self.dict = {}
	stored_resource = dict
	settings = plugin.get_editor_interface().get_editor_settings()
	for x in get_children():
		x.queue_free()

	size_flags_horizontal = SIZE_EXPAND_FILL
	init_prop_container = HBoxContainer.new()
	init_prop_container.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var prop_list = dict.get_property_list()
	var cur_name
	var i := -1
	for x in prop_list:
		if x["usage"] & PROPERTY_USAGE_EDITOR == 0:
			continue
		
		i += 1
		if i < 3: continue  # First 3 are Resource props.
		cur_name = x["name"]
		self.dict[cur_name] = stored_resource[cur_name]
		add_child(create_property_container(cur_name))
	
	self.dict["resource_name"] = stored_resource.resource_name
	add_child(create_property_container("resource_name"))
	
	rect_min_size.x = 0
	rect_size.x = 0
	hide()
	show()  # to update rect


func create_property_container(k):
	var c = init_prop_container.duplicate()
	var label = Label.new()
	label.text = k.capitalize()
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)
	c.add_child(create_property_control_for_type(typeof(dict[k]), dict[k], k, false))

	return c


func update_variant(key, value, is_rename):
	dict[key] = value
	stored_resource.set(key, value)
	emit_signal("value_changed", stored_resource)
