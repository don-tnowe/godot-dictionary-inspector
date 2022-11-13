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
var recursion_color
var init_prop_container
var last_type_k := TYPE_STRING
var last_type_v := TYPE_REAL


func display(dict, plugin : EditorPlugin):
	self.plugin = plugin
	self.dict = dict
	settings = plugin.get_editor_interface().get_editor_settings()
	recursion_color = get_recursion_color()
	add_child(create_header())

	size_flags_horizontal = SIZE_EXPAND_FILL
	init_prop_container = HBoxContainer.new()
	init_prop_container.size_flags_horizontal = SIZE_EXPAND_FILL
	init_prop_container.add_constant_override("separation", 0)

	for k in dict.keys() if dict is Dictionary else dict.size():
		# YES, the Array editor is just the Dictionary editor but without keys.
		# That's why this check is necessary.
		add_child(create_property_container(k))
		last_type_k = typeof(k)
		last_type_v = typeof(dict[k])
	
	add_child(create_color_rect())
	rect_min_size.x = 0
	rect_size.x = 0


func get_recursion_color():
	var cur_parent = self
	var recursion_level: = -4
	while true:
		recursion_level += 1
		cur_parent = cur_parent.get_parent()
		if cur_parent is EditorInspector:
			break
	
	var tint = settings.get_setting("docks/property_editor/subresource_hue_tint")
	var color = settings.get_setting("interface/theme/accent_color")
	color = color.blend(Color.from_hsv(
		color.h + recursion_level * 0.066,
		color.s,
		color.v,
		tint
	))
	color.a = 0.66
	return color


func create_header():
	var result = MarginContainer.new()
	result.add_child(create_color_rect())
	result.add_child(create_add_button())
	# result.rect_min_size.y = get_child(0).get_child(1).get_minimum_size().y + 4
	return result


func create_color_rect() -> ColorRect:
	var color_rect = ColorRect.new()
	color_rect.rect_min_size = Vector2(2, 2)
	color_rect.color = recursion_color
	color_rect.mouse_filter = MOUSE_FILTER_IGNORE
	return color_rect


func create_add_button():
	var result = Button.new()
	result.text = "Add Entry"
	result.icon = get_icon("Add", "EditorIcons")
	result.size_flags_vertical = SIZE_SHRINK_CENTER
	result.size_flags_horizontal = SIZE_SHRINK_CENTER
	result.rect_min_size.x = result.get_minimum_size().x + 64.0
	result.connect("pressed", self, "_on_add_button_pressed")
	return result


func create_property_container(k):
	var c = init_prop_container.duplicate()
	c.add_child(create_color_rect())
	c.add_child(create_type_switcher(typeof(k), k, true))
	c.add_child(create_property_control_for_type(typeof(k), k, k, true))
	c.add_child(create_type_switcher(typeof(dict[k]), k, false))
	c.add_child(create_property_control_for_type(typeof(dict[k]), dict[k], k, false))
	c.add_child(create_delete_button(k))
	c.add_child(create_color_rect())

	return c


func create_delete_button(key):
	var result = Button.new()
	result.text = ""
	result.icon = get_icon("Remove", "EditorIcons")
	result.connect("pressed", self, "_on_property_deleted", [key, result])
	return result


func create_type_switcher(type, key, is_key) -> TypeOptionButton:
	var result = TypeOptionButton.new()
	result.call_deferred("_on_item_selected", type)
	result.connect("item_selected", self, "_on_property_control_type_changed", [result, key, is_key])
	return result


func create_property_control_for_type(type, initial_value, key, is_key) -> Control:
	var result
	var settings = plugin.get_editor_interface().get_editor_settings()
	var float_step = settings.get_setting("interface/inspector/default_float_step")
	match(type):
		TYPE_NIL:
			result = Label.new()
			result.text = "[null]"

		TYPE_BOOL:
			result = CheckBox.new()
			result.text = "On"

		TYPE_INT:
			result = SpinBox.new()
			result.value = initial_value

		TYPE_REAL:
			result = FloatPropertyEditor.new(initial_value, float_step)

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

		TYPE_OBJECT:
			result = Label.new()
			result.text = "[not supported yet]"

		TYPE_DICTIONARY:
			result = get_script().new()
			result.call_deferred("display", initial_value, plugin)

		TYPE_ARRAY:
			result = load("res://addons/dictionary_inspector/elements/array_property_editor.gd").new()  # Cyclic ref
			result.call_deferred("display", initial_value, plugin)

		TYPE_RAW_ARRAY, TYPE_INT_ARRAY, TYPE_REAL_ARRAY, TYPE_STRING_ARRAY,\
		TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_COLOR_ARRAY:
			result = load("res://addons/dictionary_inspector/elements/packed_array_property_editor.gd").new()  # Also cyclic ref (i love inheritance) (but not in gdscript) (i also love comments that make lines really long)
			result.call_deferred("display", initial_value, plugin)
		
		_:
			result = Label.new()
			result.text = "Not Supported"
	
	connect_control(result, type, key, is_key)
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	return result


func connect_control(control, type, key, is_key):
	var signal_name := "value_changed"
	if control is BaseButton:
		signal_name = "toggled"
		
	elif control is LineEdit:
		signal_name = "text_changed"

	elif control is ColorPickerButton:
		signal_name = "color_changed"

	elif control is Label || control.get_script() == get_script():
		# Can't connect anything, but some drawers do use a Label.
		return
	
	if control.is_connected(signal_name, self, "_on_property_control_value_changed"):
		control.disconnect(signal_name, self, "_on_property_control_value_changed")

	control.connect(signal_name, self, "_on_property_control_value_changed", [control, key, is_key])


func update_variant(key, value, is_rename):
	if is_rename:
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
	move_child(new_node, 1)


func _on_property_control_value_changed(value, control, key, is_rename = false):
	if is_rename:
		connect_control(control, typeof(value), value, is_rename)

	update_variant(key, value, is_rename)


func _on_property_control_type_changed(type, control, key, is_key = false):
	var value = default_per_class[type]
	var new_editor = create_property_control_for_type(type, value, value if is_key else key, is_key)
	control.get_parent().get_child(control.get_position_in_parent() + 1).free()
	control.get_parent().add_child_below_node(control, new_editor)
	update_variant(key, value, is_key)
	if is_key:
		last_type_k = type

	else:
		last_type_v = type


func _on_property_deleted(key, control):
	dict.erase(key)
	control.get_parent().queue_free()
	emit_signal("value_changed", dict)
