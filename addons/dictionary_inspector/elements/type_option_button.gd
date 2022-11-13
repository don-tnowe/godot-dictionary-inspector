class_name TypeOptionButton
extends OptionButton


const typenames = [
	"Remove",
	"bool",
	"int",
	"float",
	"String",
	"Vector2",
	"Rect2",
	"Vector3",
	"Transform2D",
	"Plane",
	"Quat",
	"AABB",
	"Basis",
	"Transform",
	"Color",
	"NodePath",
	"RID",
	"Object",
	"Dictionary",
	"Array",
	"PoolByteArray",
	"PoolIntArray",
	"PoolRealArray",
	"PoolStringArray",
	"PoolVector2Array",
	"PoolVector3Array",
	"PoolColorArray",
]

export(Array, Texture) var custom_icons


func _ready():
	if custom_icons == null || custom_icons.size() == 0:
		for x in typenames:
			add_type_icon_item(x)

	else:
		for i in custom_icons.size():
			add_icon_item(custom_icons[i], typenames[i])
	
	text = ""
	set_item_text(0, "DELETE ENTRY")
	connect("item_selected", self, "_on_item_selected")


func add_type_icon_item(name):
	add_icon_item(get_icon(name, "EditorIcons"), name)
	get_popup().set_item_as_radio_checkable(get_item_count() - 1, false)


func _on_item_selected(index):
	icon = get_item_icon(index)
	text = ""
