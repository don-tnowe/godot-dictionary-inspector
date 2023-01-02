@tool
class_name ThemeIconButton
extends Button

@export var icon_name := "Node": set = _set_icon_name


func _ready():
	_set_icon_name(icon_name)


func _set_icon_name(v):
	icon_name = v
	if has_theme_icon(v, "EditorIcons"):
		icon = get_theme_icon(v, "EditorIcons")
