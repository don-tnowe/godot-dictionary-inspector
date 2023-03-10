@tool
extends OptionButton


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

@export var custom_icons : Array[Texture] = []


func _ready():
	if custom_icons == null || custom_icons.size() == 0:
		for x in typenames:
			add_type_icon_item(x)

	else:
		for i in custom_icons.size():
			add_icon_item(custom_icons[i], typenames[i])

	fit_to_longest_item = false
	set_item_text(0, "DELETE ENTRY")
	_on_item_selected(selected)
	connect("item_selected", _on_item_selected)


func add_type_icon_item(typename):
	add_icon_item(get_theme_icon(typename, "EditorIcons"), typename, typenames[typename])
	get_popup().set_item_as_radio_checkable(get_item_count() - 1, false)


func _on_item_selected(index):
	icon = get_item_icon(index)
	text = ""
