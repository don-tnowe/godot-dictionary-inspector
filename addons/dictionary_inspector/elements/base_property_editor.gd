@tool
extends VBoxContainer

signal value_changed(new_value)

const DictionaryInspectorArrayIndex = preload("res://addons/dictionary_inspector/elements/special_buttons/array_index.gd")
const TypeOptionButton = preload("res://addons/dictionary_inspector/elements/special_buttons/type_option_button.gd")

var type_by_name = {
	"null" : TYPE_NIL,
	"bool" : TYPE_BOOL,
	"int" : TYPE_INT,
	"float" : TYPE_FLOAT,
	"String" : TYPE_STRING,
	"Vector2" : TYPE_VECTOR2,
	"Vector2i" : TYPE_VECTOR2I,
	"Rect2" : TYPE_RECT2,
	"Rect2i" : TYPE_RECT2I,
	"Vector3" : TYPE_VECTOR3,
	"Vector3i" : TYPE_VECTOR3I,
	"Transform2D" : TYPE_TRANSFORM2D,
	"Vector4" : TYPE_VECTOR4,
	"Vector4i" : TYPE_VECTOR4I,
	"Plane" : TYPE_PLANE,
	"Quaternion" : TYPE_QUATERNION,
	"AABB" : TYPE_AABB,
	"Basis" : TYPE_BASIS,
	"Transform3D" : TYPE_TRANSFORM3D,
	"Projection" : TYPE_PROJECTION,
	"Color" : TYPE_COLOR,
	"StringName" : TYPE_STRING_NAME,
	"NodePath" : TYPE_NODE_PATH,
	"RID" : TYPE_RID,
	"Object" : TYPE_OBJECT,
	"Callable" : TYPE_CALLABLE,
	"Signal" : TYPE_SIGNAL,
	"Dictionary" : TYPE_DICTIONARY,
	"Array" : TYPE_ARRAY,
	"PackedByteArray" : TYPE_PACKED_BYTE_ARRAY,
	"PackedInt32Array" : TYPE_PACKED_INT32_ARRAY,
	"PackedInt64Array" : TYPE_PACKED_INT64_ARRAY,
	"PackedFloat32Array" : TYPE_PACKED_FLOAT32_ARRAY,
	"PackedFloat64Array" : TYPE_PACKED_FLOAT64_ARRAY,
	"PackedStringArray" : TYPE_PACKED_STRING_ARRAY,
	"PackedVector2Array" : TYPE_PACKED_VECTOR2_ARRAY,
	"PackedVector3Array" : TYPE_PACKED_VECTOR3_ARRAY,
	"PackedColorArray" : TYPE_PACKED_COLOR_ARRAY,
}

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

var init_delete_button
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

	init_delete_button = Button.new()
	init_delete_button.icon = get_theme_icon("Remove", "EditorIcons")
	init_delete_button.tooltip_text = "Delete entry"

	add_child(create_add_button())
	add_all_items(collection)

	custom_minimum_size.x = 0
	size.x = 0
	hide()
	show()  # to update rect


func create_add_button():
	return Control.new()


func add_all_items(collection):
	for x in collection:
		add_child(create_item_container(x))


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
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_COLOR_ARRAY,\
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY,\
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,\
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY:
			# This big boy will also handle the distinction.
			var script_file = "res://addons/dictionary_inspector/elements/special_buttons/collection_header_button.gd"
			result = load(script_file).new(initial_value, plugin)
			result.bottom_control_available.connect(container.add_sibling)

		_:
			result = Label.new()
			result.text = "Not Supported"
	
	connect_control(result, type, container, is_key)
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	return result





func get_type_from_string(type_name : String):
	if type_by_name.has(type_name):
		return type_by_name[type_name]
	elif type_exists(type_name):
		return TYPE_OBJECT
	else :
		return null
	


func get_default_for_type(type, is_key = false):
	var type_hint = TYPE_OBJECT if type is String else type
	var new_value = default_per_class[type_hint]
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
			new_value = new_value.from_hsv(new_value.h + 0.01, new_value.s, new_value.v)

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
	if type == 0 :
		type = TYPE_OBJECT
	var result = TypeOptionButton.new()
	result.get_popup().connect("index_pressed", _on_property_control_type_changed.bind(result, container, is_key))

	result._on_item_selected.call_deferred(type, true)
	return result


func update_variant(key, value, is_rename = false):
	print(key,value)
	stored_collection[key] = value
	emit_signal("value_changed", stored_collection)


func get_container_index(container) -> int:
	var i := 0
	for x in get_vbox_recursive_children(self):
		if x == container:
			return i

		if x is HBoxContainer:
			i += 1

	return -1


func get_vbox_recursive_children(vbox :VBoxContainer):
	var result := []
	for child in vbox.get_children() : 
		if child is VBoxContainer:
			result.append_array(get_vbox_recursive_children(child))
		else:
			result.append(child)
	return result


func _on_property_control_value_changed(value, control, container, is_rename = false):
	print(get_container_index(container))
	update_variant(get_container_index(container), value, is_rename)


func _on_property_control_type_changed(type_index, control, container, is_key = false):
	pass
