@tool
extends VBoxContainer

signal value_changed(new_value)

const DictionaryInspectorArrayIndex = preload("res://addons/dictionary_inspector/elements/special_buttons/array_index.gd")
const TypeOptionButton = preload("res://addons/dictionary_inspector/elements/special_buttons/type_option_button.gd")

var default_per_class = [
	null,
	false,
	0,
	0.0,
	"Enter value...",
	Vector2(),
	Vector2i(),
	Rect2(),
	Rect2i(),
	Vector3(),
	Vector3i(),
	Transform2D(),
	Vector4(),
	Vector4i(),
	Plane(),
	Quaternion(),
	AABB(),
	Basis(),
	Transform3D(),
	Projection(),
	Color(),
	&"Enter value...",
	NodePath(),
	RID(),
	null,
	Callable(),
	Signal(),
	Dictionary(),
	Array(),
	PackedByteArray(),
	PackedInt32Array(),
	PackedInt64Array(),
	PackedFloat32Array(),
	PackedFloat64Array(),
	PackedStringArray(),
	PackedVector2Array(),
	PackedVector3Array(),
	PackedColorArray(),
]

var stored_collection
var plugin
var settings
var parent_stylebox

var init_prop_container
var last_type_v := TYPE_FLOAT


func display(collection, plugin : EditorPlugin):
	self.plugin = plugin
	self.stored_collection = collection
	settings = plugin.get_editor_interface().get_editor_settings()
	for x in get_children():
		x.free()

	size_flags_horizontal = SIZE_EXPAND_FILL
	init_prop_container = HBoxContainer.new()
	init_prop_container.size_flags_horizontal = SIZE_EXPAND_FILL

	add_child(create_add_button())
	add_all_items(collection)

	custom_minimum_size.x = 0
	size.x = 0
	hide()
	show()  # to update rect


func create_add_button():
	return Control.new()


func add_all_items(collection):
	if !collection.is_empty():
		for x in collection:
			add_child(create_item_container(x))
	else:
		add_child(create_item_container(0))


func create_item_container(k):
	var c = init_prop_container.duplicate()
	var label = Label.new()
	label.text = str(k)
	return label


func create_item_control_for_type(type, initial_value, container, is_key) -> Control:
	var result
	var settings = plugin.get_editor_interface().get_editor_settings()
	var float_step = settings.get_setting("interface/inspector/default_float_step")
	match(type):
		TYPE_BOOL:
			result = CheckBox.new()
			result.text = "On"
			result.button_pressed = initial_value

		TYPE_INT:
			result = EditorSpinSlider.new()
			result.allow_lesser = true
			result.allow_greater = true
			result.value = initial_value

		TYPE_FLOAT:
			result = EditorSpinSlider.new()
			result.allow_lesser = true
			result.allow_greater = true
			result.step = float_step
			result.value = initial_value
			result.hide_slider = true

		TYPE_STRING, TYPE_STRING_NAME:
			result = LineEdit.new()
			result.text = initial_value

		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_RECT2, TYPE_RECT2I,\
		TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I,\
		TYPE_TRANSFORM2D, TYPE_PLANE, TYPE_QUATERNION, TYPE_AABB,\
		TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_PROJECTION:
			# This big boy will handle the distinction.
			result = load("res://addons/dictionary_inspector/elements/tensor_property_editor.gd")\
				.new(initial_value, type, float_step)

		TYPE_COLOR:
			result = ColorPickerButton.new()
			result.color = initial_value

		TYPE_NODE_PATH:
			result = LineEdit.new()
			result.text = initial_value

		TYPE_RID:
			result = Label.new()
			result.text = "[not supported yet]"

		TYPE_OBJECT, TYPE_NIL,\
		TYPE_DICTIONARY, TYPE_ARRAY,\
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_STRING_ARRAY,\
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY,\
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,\
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY:
			# This big boy will also handle the distinction.
			var script_file = "res://addons/dictionary_inspector/elements/special_buttons/collection_header_button.gd"
			result = load(script_file).new(initial_value, plugin)
			result.connect("bottom_control_available", _on_collection_control_available.bind(result))

		_:
			result = Label.new()
			result.text = "Not Supported"
	
	connect_control(result, type, container, is_key)
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	return result


func _on_collection_control_available(new_control, created_by_control):
	var below_node = created_by_control.get_parent()
	if below_node is EditorResourcePicker:
		# Object editor buttons get replaced by a Picker and become their child.
		below_node = below_node.get_parent()

	add_child(new_control)
	move_child(new_control, below_node.get_index() + 1)


func get_default_for_type(type, is_key = false):
	var new_value = default_per_class[type]
	if type == TYPE_DICTIONARY || type == TYPE_ARRAY:
		return new_value.duplicate()

	if !is_key: return new_value
	while stored_collection.has(new_value):
		if type == TYPE_INT || type == TYPE_FLOAT:
			new_value += 1

		elif type == TYPE_STRING || type == TYPE_NODE_PATH || type == TYPE_STRING_NAME:
			new_value += "2"

		elif type == TYPE_VECTOR2 || type == TYPE_VECTOR3 || type == TYPE_VECTOR4:
			new_value.x += 1.0

		elif type == TYPE_VECTOR2I || type == TYPE_VECTOR3I || type == TYPE_VECTOR4I:
			new_value.x += 1

		elif type == TYPE_PLANE || type == TYPE_QUATERNION:
			new_value.x += 1.0

		elif type == TYPE_RECT2 || type == TYPE_RECT2I || type == TYPE_AABB:
			new_value.position.x += 1

		elif type == TYPE_TRANSFORM2D || type == TYPE_TRANSFORM3D:
			new_value.origin.x += 1.0

		elif type == TYPE_BASIS || type == TYPE_PROJECTION:
			new_value.x.x += 1.0

		elif type == TYPE_COLOR:
			new_value = Color(randi(), 1.0)

		elif type == TYPE_OBJECT:
			return new_value

		else:
			return new_value

	return new_value


func connect_control(control, type, container, is_key):
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

	if control.is_connected(signal_name, _on_property_control_value_changed):
		control.disconnect(signal_name, _on_property_control_value_changed)

	control.connect(signal_name, _on_property_control_value_changed.bind(control, container, is_key))


func create_type_switcher(type, container, is_key) -> TypeOptionButton:
	var result
	if typeof(stored_collection) == TYPE_ARRAY && stored_collection.is_typed():
		result = TypeOptionButton.new(stored_collection.get_typed_builtin())
	else:
		result = TypeOptionButton.new()

	result._on_item_selected.call_deferred(type)
	result.call_deferred("_on_item_selected", result.get_type_dict_index(type))
	result.get_popup().connect("index_pressed", _on_property_control_type_changed_parse_type.bind(result, container, is_key), CONNECT_DEFERRED)

	return result


func update_variant(key, value, is_rename = false):
	stored_collection[key] = value
	emit_signal("value_changed", stored_collection)


func get_container_index(container) -> int:
	var i := 0
	for x in get_children():
		if x == container:
			return i

		if x is HBoxContainer:
			i += 1

	return -1


func _on_property_control_value_changed(value, control, container, is_rename = false):
	update_variant(get_container_index(container), value, is_rename)


func _on_property_control_type_changed(type, control, container, is_key = false):
	pass

func _on_property_control_type_changed_parse_type(type, control, container, is_key = false):
	var typenames = control.typenames
	type = typenames[typenames.keys()[type]]
	_on_property_control_type_changed(type, control, container, is_key)
