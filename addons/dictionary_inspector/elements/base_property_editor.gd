tool
class_name BaseCollectionPropertyEditor
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

var stored_collection
var plugin
var settings

var init_prop_container
var last_type_v := TYPE_REAL


func display(collection, plugin : EditorPlugin):
	self.plugin = plugin
	self.stored_collection = collection
	settings = plugin.get_editor_interface().get_editor_settings()
	for x in get_children():
		x.queue_free()

	size_flags_horizontal = SIZE_EXPAND_FILL
	init_prop_container = HBoxContainer.new()
	init_prop_container.size_flags_horizontal = SIZE_EXPAND_FILL

	add_child(create_add_button())
	add_all_properties(collection)

	rect_min_size.x = 0
	rect_size.x = 0
	hide()
	show()  # to update rect


func create_add_button():
	return Control.new()


func add_all_properties(collection):
	for x in collection:
		add_child(create_property_container(x))


func create_property_container(k):
	var c = init_prop_container.duplicate()
	var label = Label.new()
	label.text = str(k)
	return label


func create_property_control_for_type(type, initial_value, key, is_key) -> Control:
	var result
	var settings = plugin.get_editor_interface().get_editor_settings()
	var float_step = settings.get_setting("interface/inspector/default_float_step")
	match(type):
		TYPE_BOOL:
			result = CheckBox.new()
			result.text = "On"
			result.pressed = initial_value

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

		TYPE_OBJECT, TYPE_NIL,\
		TYPE_DICTIONARY, TYPE_ARRAY,\
		TYPE_RAW_ARRAY, TYPE_INT_ARRAY, TYPE_REAL_ARRAY, TYPE_STRING_ARRAY,\
		TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_COLOR_ARRAY:
			# This big boy will also handle the distinction.
			var script_file = "res://addons/dictionary_inspector/elements/collection_header_button.gd"
			result = load(script_file).new(initial_value, plugin)
			result.connect("bottom_control_available", self, "_on_collection_control_available", [result])

		_:
			result = Label.new()
			result.text = "Not Supported"
	
	connect_control(result, type, key, is_key)
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	return result


func _on_collection_control_available(new_control, created_by_control):
	var below_node = created_by_control.get_parent()
	if below_node is EditorResourcePicker:
		# Object editor buttons get replaced by a Picker and become their child.
		below_node = below_node.get_parent()

	add_child_below_node(below_node, new_control)



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



func create_type_switcher(type, key, is_key) -> TypeOptionButton:
	var result = TypeOptionButton.new()
	result.call_deferred("_on_item_selected", type)
	result.get_popup().connect("index_pressed", self, "_on_property_control_type_changed", [result, key, is_key])

	return result


func update_variant(key, value, is_rename = false):
	stored_collection[key] = value
	emit_signal("value_changed", stored_collection)


func _on_property_control_value_changed(value, control, key, is_rename = false):
	update_variant(key, value, is_rename)
