tool
class_name ObjectPropertyEditor
extends BaseCollectionPropertyEditor


func add_all_properties(collection):
	var prop_list = collection.get_property_list()
	var cur_name
	var i := -1
	for x in prop_list:
		if x["usage"] & PROPERTY_USAGE_EDITOR == 0:
			continue
		
		i += 1
		if i < 3: continue  # First 3 are Resource props.
		cur_name = x["name"]
		add_child(create_property_container(cur_name))
	
	add_child(create_property_container("resource_name"))


func create_property_container(k):
	var c = init_prop_container.duplicate()
	var label = Label.new()
	label.text = k.capitalize()
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)
	c.add_child(create_property_control_for_type(typeof(stored_collection[k]), stored_collection[k], k, false))

	return c
