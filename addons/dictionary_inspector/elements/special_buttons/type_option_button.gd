@tool
extends OptionButton


const typenames = {
	&"Remove" : 0,
	&"bool" : 1,
	&"int" : 2,
	&"float" : 3,
	&"String" : 4,
	&"Vector2" : 5,
	&"Vector2i" : 6,
	&"Rect2" : 7,
	&"Rect2i" : 8,
	&"Vector3" : 9,
	&"Vector3i" : 10,
	&"Transform2D" : 11,
	&"Vector4" : 12,
	&"Vector4i" : 13,
	&"Plane" : 14,
	&"Quaternion" : 15,
	&"AABB" : 16,
	&"Basis" : 17,
	&"Transform3D" : 18,
	&"Projection" : 19,
	&"Color" : 20,
	&"StringName" : 21,
	&"NodePath" : 22,
	# &"---​" : 23,
	&"Object" : 24,
	# &"---​​" : 25,
	# &"---​​​" : 26,
	&"Dictionary" : 27,
	&"Array" : 28,
	&"PackedByteArray" : 29,
	&"PackedInt32Array" : 30,
	&"PackedInt64Array" : 31,
	&"PackedFloat32Array" : 32,
	&"PackedFloat64Array" : 33,
	&"PackedStringArray" : 34,
	&"PackedVector2Array" : 35,
	&"PackedVector3Array" : 36,
	&"PackedColorArray" : 37,
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
