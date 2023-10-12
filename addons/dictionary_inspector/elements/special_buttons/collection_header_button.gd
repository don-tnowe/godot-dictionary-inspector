@tool
extends Button

# just copy these here for now to have easier access
const typenames = {
	&"Remove" : 0,
	&"bool" : TYPE_BOOL,
	&"int" : TYPE_INT,
	&"float" : TYPE_FLOAT,
	&"String" : TYPE_STRING,
	&"Vector2" : TYPE_VECTOR2,
	&"Vector2i" : TYPE_VECTOR2I,
	&"Rect2" : TYPE_RECT2,
	&"Rect2i" : TYPE_RECT2I,
	&"Vector3" : TYPE_VECTOR3,
	&"Vector3i" : TYPE_VECTOR3I,
	&"Transform2D" : TYPE_TRANSFORM2D,
	&"Vector4" : TYPE_VECTOR4,
	&"Vector4i" : TYPE_VECTOR4I,
	&"Plane" : TYPE_PLANE,
	&"Quaternion" : TYPE_QUATERNION,
	&"AABB" : TYPE_AABB,
	&"Basis" : TYPE_BASIS,
	&"Transform3D" : TYPE_TRANSFORM3D,
	&"Projection" : TYPE_PROJECTION,
	&"Color" : TYPE_COLOR,
	&"StringName" : TYPE_STRING_NAME,
	&"NodePath" : TYPE_NODE_PATH,
#	&"RID" : TYPE_RID,
	&"Object" : TYPE_OBJECT,
#	&"Callable" : TYPE_CALLABLE,
#	&"Signal" : TYPE_SIGNAL,
	&"Dictionary" : TYPE_DICTIONARY,
	&"Array" : TYPE_ARRAY,
	&"PackedByteArray" : TYPE_PACKED_BYTE_ARRAY,
	&"PackedInt32Array" : TYPE_PACKED_INT32_ARRAY,
	&"PackedInt64Array" : TYPE_PACKED_INT64_ARRAY,
	&"PackedFloat32Array" : TYPE_PACKED_FLOAT32_ARRAY,
	&"PackedFloat64Array" : TYPE_PACKED_FLOAT64_ARRAY,
	&"PackedStringArray" : TYPE_PACKED_STRING_ARRAY,
	&"PackedVector2Array" : TYPE_PACKED_VECTOR2_ARRAY,
	&"PackedVector3Array" : TYPE_PACKED_VECTOR3_ARRAY,
	&"PackedColorArray" : TYPE_PACKED_COLOR_ARRAY,
}

func get_type_dict_index(type):
	var i = 0
	var typekeys = typenames.keys()
	for key in typekeys:
		if (typenames[key] == type):
			return i
		i += 1

signal value_changed(new_value)
signal bottom_control_available(control)

var stored_collection
var plugin

var color_rect
var open_button
var bottom_control
var collection_editor
var stylebox


func _init(collection, plugin):
	stored_collection = collection
	self.plugin = plugin


func _ready():
	stylebox = get_recursion_style()
	color_rect = ColorRect.new()
	add_child(color_rect)

	color_rect.hide()
	color_rect.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	color_rect.offset_bottom = 4
	color_rect.offset_right = 0
	color_rect.show_behind_parent = true
	color_rect.mouse_filter = MOUSE_FILTER_IGNORE
	color_rect.color = stylebox.border_color
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	connect("pressed", _on_pressed)
	_on_value_changed(stored_collection)
	if stored_collection is Object || stored_collection == null:
		await get_tree().process_frame
		var picker_script = preload("res://addons/dictionary_inspector/elements/special_buttons/custom_resource_picker.gd")
		var picker = picker_script.new(stored_collection, plugin)
		replace_by(picker)
		picker.size_flags_horizontal = SIZE_EXPAND_FILL
		picker.add_child(self)
		picker.get_child(0).connect("pressed", _on_pressed)
		picker.connect("resource_changed", _on_value_changed)
		hide()


func _exit_tree():
	if is_instance_valid(bottom_control):
		bottom_control.queue_free()


func _can_drop_data(at_position : Vector2, data):
	if !data.has(&"type"): return false
	if data.type != &"files": return false
	if stored_collection is Array:
		if stored_collection.is_typed() && stored_collection.get_typed_builtin() != TYPE_OBJECT:
			return false

	return true


func _drop_data(at_position : Vector2, data):
	if !data.has(&"type"): return false
	if data.type != &"files": return false
	if stored_collection is Array:
		if stored_collection.is_typed() && stored_collection.get_typed_builtin() != TYPE_OBJECT:
			return false

		for x in data.files:
			if load(x) == null: continue
			stored_collection.append(load(x))

	if stored_collection is Dictionary:
		for x in data.files:
			if load(x) == null: continue
			stored_collection[load(x)] = load(x)

	if bottom_control != null:
		collection_editor.display(stored_collection, plugin)

	_on_value_changed(stored_collection)
	return true


func _on_pressed():
	if stored_collection == null: return
	if bottom_control == null:
		flat = true

		bottom_control = PanelContainer.new()
		bottom_control.add_theme_stylebox_override("panel", stylebox)

		collection_editor = (
			load("res://addons/dictionary_inspector/elements/dict_property_editor.gd")
			if stored_collection is Dictionary else
			load("res://addons/dictionary_inspector/elements/array_property_editor.gd")
			if stored_collection is Array else
			load("res://addons/dictionary_inspector/elements/object_property_editor.gd")
			if stored_collection is Object else
			load("res://addons/dictionary_inspector/elements/packed_array_property_editor.gd")
		).new()

		collection_editor.parent_stylebox = stylebox
		bottom_control.add_child(collection_editor)
		collection_editor.connect("value_changed", _on_value_changed)
		color_rect.show()
		emit_signal("bottom_control_available", bottom_control)

	else:
		flat = !flat
		bottom_control.visible = flat
		color_rect.visible = flat

	if flat:
		collection_editor.display(stored_collection, plugin)


func get_recursion_style():
	var cur_parent = self
	var recursion_level: = -4
	while true:
		recursion_level += 1
		cur_parent = cur_parent.get_parent()
		if cur_parent is EditorInspector:
			break

	var settings = plugin.get_editor_interface().get_editor_settings()
	var style = get_theme_stylebox("sub_inspector_bg" + str(((recursion_level + 1) / 3) % 16), "Editor")
	return style


func _on_value_changed(value):
	if value != null && !value is Object:
		text = "%s (%ssize %s)" % [
			(
				"Dictionary" if value is Dictionary else
				"Array" if value is Array else
				"PackedArray"
			),
			str(typenames.keys()[get_type_dict_index(value.get_typed_builtin())]) + ", " if value is Array && value.is_typed() else "",
			value.size(),
		]
	stored_collection = value
	emit_signal("value_changed", value)
