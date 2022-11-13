tool
class_name CollectionHeaderButton
extends Button

signal value_changed(new_value)
signal bottom_control_available(control)

var stored_collection
var plugin

var color_rect
var open_button
var bottom_control
var collection_editor
var color
var nested := false


func _init(collection, plugin):
	stored_collection = collection
	self.plugin = plugin


func _ready():
	color = get_recursion_color()
	color_rect = ColorRect.new()
	color_rect.color = color
	color_rect.hide()
	color_rect.set_anchors_and_margins_preset(PRESET_WIDE)
	color_rect.margin_bottom = 4
	color_rect.margin_right = -1 if nested else 0
	color_rect.show_behind_parent = true
	color_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(color_rect)
	connect("pressed", self, "_on_pressed")

	_on_value_changed(stored_collection)


func _exit_tree():
	if is_instance_valid(bottom_control):
		bottom_control.queue_free()


func _on_pressed():
	if bottom_control == null:
		color_rect.show()

		bottom_control = MarginContainer.new()
		bottom_control.add_constant_override("margin_top", 1)
		bottom_control.add_constant_override("margin_left", 1)
		bottom_control.add_constant_override("margin_bottom", 1)
		bottom_control.add_constant_override("margin_right", 1 if nested else 0)
		
		var color_border = ColorRect.new()
		color_border.color = color
		color_border.mouse_filter = MOUSE_FILTER_IGNORE
		bottom_control.add_child(color_border)

		var panel_container = MarginContainer.new()
		panel_container.add_child(Panel.new())
		panel_container.get_child(0).self_modulate.a = 0.75
		panel_container.add_constant_override("margin_top", 2)
		panel_container.add_constant_override("margin_left", 2)
		panel_container.add_constant_override("margin_bottom", 2)
		panel_container.add_constant_override("margin_right", 2)
		bottom_control.add_child(panel_container)

		collection_editor = (
			DictPropertyEditor
			if stored_collection is Dictionary else
			ArrayPropertyEditor
			if stored_collection is Array else
			PackedArrayPropertyEditor
		).new()
		
		panel_container.add_child(collection_editor)
		collection_editor.display(stored_collection, plugin)
		collection_editor.connect("value_changed", self, "_on_value_changed")
		emit_signal("bottom_control_available", bottom_control)

	else:
		color_rect.visible = !color_rect.visible
		bottom_control.visible = !bottom_control.visible
		if bottom_control.visible:
			collection_editor.display(stored_collection, plugin)


func get_recursion_color():
	var cur_parent = self
	var recursion_level: = -4
	while true:
		recursion_level += 1
		cur_parent = cur_parent.get_parent()
		if cur_parent is EditorInspector:
			break
	
	if recursion_level > 0: nested = true 
	var settings = plugin.get_editor_interface().get_editor_settings()
	var tint = settings.get_setting("docks/property_editor/subresource_hue_tint")
	var color = settings.get_setting("interface/theme/accent_color")
	color = color.blend(Color.from_hsv(
		color.h + recursion_level * 0.033,
		color.s,
		color.v,
		tint
	))
	color.a = 0.55
	return color


func _on_value_changed(value):
	text = (
		("Dictionary" if value is Dictionary else "Array")
		+ " (size " + str(value.size()) + ")"
	)
	stored_collection = value
	emit_signal("value_changed", value)
