tool
class_name DictPropertyEditor
extends VBoxContainer

signal value_changed(new_value)

const default_per_class = [
	null,
	false,
	0,
	0.0,
	"Enter value...",
	Vector2(),
	Rect2(),
	Vector3(),
	Transform2D(),
	Plane(),
	Quat(),
	AABB(),
	Basis(),
	Transform(),
	Color(),
	NodePath(),
	RID(),
	null,
	Dictionary(),
	Array(),
	PoolByteArray(),
	PoolIntArray(),
	PoolRealArray(),
	PoolStringArray(),
	PoolVector2Array(),
	PoolVector3Array(),
	PoolColorArray(),
]

var dict
var plugin
var settings
var editor_base_ctrl
var init_prop_container
var last_type_k := TYPE_STRING
var last_type_v := TYPE_REAL


func display(dict, plugin : EditorPlugin):
	self.plugin = plugin
	self.dict = dict
	settings = plugin.get_editor_interface().get_editor_settings()
	for x in get_children():
		x.queue_free()

	# display can be called before added to scene BUT plugin is passed to display
	editor_base_ctrl = plugin.get_editor_interface().get_base_control()
	add_child(create_add_button())

	size_flags_horizontal = SIZE_EXPAND_FILL
	init_prop_container = HBoxContainer.new()
	init_prop_container.size_flags_horizontal = SIZE_EXPAND_FILL

	for k in dict.keys() if dict is Dictionary else dict.size():
		# YES, the Array editor is just the Dictionary editor but without keys.
		# That's why this check is necessary.
		add_child(create_property_container(k))
		last_type_k = typeof(k)
		last_type_v = typeof(dict[k])
	
	size_flags_stretch_ratio = 3
	rect_min_size.x = 0
	rect_size.x = 0
	hide()
	show()  # to update rect


func create_add_button():
	var button = Button.new()
	button.text = "Add Entry"
	button.icon = editor_base_ctrl.get_icon("Add", "EditorIcons")
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.rect_min_size.x = button.get_minimum_size().x + 64.0
	button.connect("pressed", self, "_on_add_button_pressed")

	var result = HBoxContainer.new()
	var color_rect = get_node("../../ColorRect").duplicate()
	color_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	# Grab the Color Rect
	result.add_constant_override("separation", 0)
	result.add_child(color_rect)
	result.add_child(button)
	result.add_child(color_rect.duplicate())
	return result


func display_value_on_label(value, label):
	if value is Color:
		label.text = "██" + value.to_html() + "██"
		label.self_modulate = value

	else:
		label.text = str(value)
		label.self_modulate = Color.white


func create_property_container(k):
	var c = init_prop_container.duplicate()
	var label = Label.new()
	display_value_on_label(k, label)

	label.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(label)

	var edit_button = Button.new()
	edit_button.icon = editor_base_ctrl.get_icon("Edit", "EditorIcons")
	edit_button.hint_tooltip = "Toggle Key/Type Editing"
	edit_button.connect("pressed", self, "toggle_property_editable", [k, c])
	c.add_child(edit_button)
	c.add_child(create_property_control_for_type(typeof(dict[k]), dict[k], k, false))

	return c


func toggle_property_editable(k, container):
	var children = container.get_children()
	if children[0].visible:
		children[0].hide()
		container.add_child(create_type_switcher(typeof(k), k, true))
		container.add_child(create_property_control_for_type(typeof(k), k, k, true))
		container.add_child(create_type_switcher(typeof(dict[k]), k, false))
		container.move_child(children[1], 4)
		container.move_child(children[2], 6)

	else:
		display_value_on_label(k, children[0])
		children[0].show()
		children[1].queue_free()
		children[2].queue_free()
		children[4].queue_free()


func create_type_switcher(type, key, is_key) -> TypeOptionButton:
	var result = TypeOptionButton.new()
	result.call_deferred("_on_item_selected", type)
	result.get_popup().connect("index_pressed", self, "_on_property_control_type_changed", [result, key, is_key])

	return result


func create_property_control_for_type(type, initial_value, key, is_key) -> Control:
	var result
	var settings = plugin.get_editor_interface().get_editor_settings()
	var float_step = settings.get_setting("interface/inspector/default_float_step")
	match(type):
		TYPE_BOOL:
			result = CheckBox.new()
			result.text = "On"

		TYPE_INT:
			result = EditorSpinSlider.new()
			result.min_value = -INF
			result.max_value = INF
			result.value = initial_value

		TYPE_REAL:
			result = EditorSpinSlider.new()
			result.min_value = -INF
			result.max_value = INF
			result.step = float_step
			result.value = initial_value
			result.hide_slider = true

		TYPE_STRING:
			result = LineEdit.new()
			result.text = initial_value

		TYPE_VECTOR2, TYPE_RECT2, TYPE_VECTOR3,\
		TYPE_TRANSFORM2D, TYPE_PLANE, TYPE_QUAT,\
		TYPE_AABB, TYPE_BASIS, TYPE_TRANSFORM:
			# This big boy will handle the distinction.
			result = TensorPropertyEditor.new(initial_value, type, float_step)

		TYPE_COLOR:
			result = ColorPickerButton.new()
			result.color = initial_value

		TYPE_NODE_PATH:
			result = LineEdit.new()
			result.text = initial_value

		TYPE_RID:
			result = Label.new()
			result.text = "[not supported yet]"

		TYPE_OBJECT, TYPE_NIL:
			# Sometimes Objects can be Nil, so type is guessed incorrectly
			result = EditorResourcePicker.new()
			result.base_type = "Resource"
			result.edited_resource = initial_value

		TYPE_DICTIONARY, TYPE_ARRAY,\
		TYPE_RAW_ARRAY, TYPE_INT_ARRAY, TYPE_REAL_ARRAY, TYPE_STRING_ARRAY,\
		TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_COLOR_ARRAY:
			var script_file = "res://addons/dictionary_inspector/elements/collection_header_button.gd"
			result = load(script_file)\
				.new(initial_value, plugin)
			result.connect("bottom_control_available", self, "_on_collection_control_available", [result])

		_:
			result = Label.new()
			result.text = "Not Supported"
	
	connect_control(result, type, key, is_key)
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	return result


func _on_collection_control_available(new_control, created_by_control):
	add_child_below_node(created_by_control.get_parent(), new_control)


func connect_control(control, type, key, is_key):
	var signal_name := "value_changed"
	
	if control is ColorPickerButton:
		signal_name = "color_changed"

	elif control is EditorResourcePicker:
		signal_name = "resource_changed"

	elif control is CheckBox:
		signal_name = "toggled"
		
	elif control is LineEdit:
		signal_name = "text_changed"

	elif control is Label || control.get_script() == get_script():
		# Can't connect anything, but some drawers do use a Label.
		return
	
	if control.is_connected(signal_name, self, "_on_property_control_value_changed"):
		control.disconnect(signal_name, self, "_on_property_control_value_changed")

	control.connect(signal_name, self, "_on_property_control_value_changed", [control, key, is_key])


func update_variant(key, value, is_rename):
	if is_rename:
		if (typeof(value) != typeof(key) || value != key):
			dict[value] = dict[key]
			dict.erase(key)
	
	else:
		dict[key] = value
	
	emit_signal("value_changed", dict)


func _on_add_button_pressed():
	if last_type_k == TYPE_BOOL:
		last_type_k = TYPE_INT

	var new_key = default_per_class[last_type_k]
	var new_value = default_per_class[last_type_v]
	while dict.has(new_key):
		if last_type_k == TYPE_INT || last_type_k == TYPE_REAL:
			new_key += 1

		elif last_type_k == TYPE_STRING || last_type_k == TYPE_NODE_PATH:
			new_key += "2"
		
		elif last_type_k == TYPE_VECTOR2 || last_type_k == TYPE_VECTOR3:
			new_key.x += 1.0

		elif last_type_k == TYPE_COLOR:
			new_key = new_key.from_hsv(new_key.h + 0.01, new_key.s, new_key.v)

		else:
			return
	
	dict[new_key] = new_value

	var new_node = create_property_container(new_key)
	add_child(new_node)
	move_child(new_node, get_child_count() - 1)
	emit_signal("value_changed", dict)


func _on_property_control_value_changed(value, control, key, is_rename = false):
	if is_rename:
		var parent_children = control.get_parent().get_children()
		var old_value = dict[key]
		update_variant(key, value, is_rename)
		connect_control(control, typeof(value), value, true)
		connect_control(parent_children[5], typeof(old_value), value, false)
		yield(get_tree(), "idle_frame")
		parent_children[1].replace_by(create_type_switcher(typeof(value), value, true))
		parent_children[1].free()
		parent_children[3].disconnect("pressed", self, "toggle_property_editable")
		parent_children[3].connect("pressed", self, "toggle_property_editable", [value, control.get_parent()])
		parent_children[4].replace_by(create_type_switcher(typeof(old_value), value, false))
		parent_children[4].free()
		return

	update_variant(key, value, is_rename)


func _on_property_control_type_changed(type, control, key, is_key = false):
	if type == 0:
		_on_property_deleted(key, control)
		return

	var value = default_per_class[type]
	update_variant(key, value, is_key)
	if is_key:
		last_type_k = type

	else:
		last_type_v = type
	
	var old_prop = control.get_parent()
	add_child_below_node(old_prop, create_property_container(value if is_key else key))
	old_prop.free()


func _on_property_deleted(key, control):
	dict.erase(key)
	control.get_parent().queue_free()
	emit_signal("value_changed", dict)
