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

func get_type_dict_index(type):
	var i = 0
	var typekeys = typenames.keys()
	for key in typekeys:
		if (typenames[key] == type):
			return i
		i += 1

@export var custom_icons : Array[Texture] = []

var _type

func _init(type = null):
	_type = type

func _ready():
	if custom_icons == null || custom_icons.size() == 0:
		var i = 0
		for x in typenames:
			add_type_icon_item(x)
			if _type:
				if typenames[x] != _type:
					set_item_disabled(i, true)
				i += 1
		set_item_disabled(0, false)

	else:
		for i in custom_icons.size():
			add_icon_item(custom_icons[i], typenames[i])

	fit_to_longest_item = false
	set_item_text(0, "DELETE ENTRY")
	_on_item_selected(selected)
	# connect("item_selected", _on_item_selected)
	get_popup().id_pressed.connect(_on_item_selected)

func add_type_icon_item(typename):
	var icon = null
	if has_theme_icon(typename, "EditorIcons"):
		icon = get_theme_icon(typename, "EditorIcons")

	add_icon_item(icon, typename, typenames[typename])
	get_popup().set_item_as_radio_checkable(get_item_count() - 1, false)


func _on_item_selected(index):
	icon = get_item_icon(index)
	set_deferred(&"text", "")
