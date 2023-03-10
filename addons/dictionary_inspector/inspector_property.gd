@tool
extends EditorProperty

var property_control
var current_value

var plugin : EditorPlugin


func _init(current_value, plugin):
	self.current_value = current_value
	self.plugin = plugin

	property_control = load("res://addons/dictionary_inspector/elements/special_buttons/collection_header_button.gd")\
		.new(current_value, plugin)
	add_child(property_control)
	add_focusable(property_control)
	property_control.connect("bottom_control_available", _on_bottom_control_available)
	property_control.connect("value_changed", _on_collection_changed)


func _on_bottom_control_available(bottom_control):
	add_child(bottom_control)
	set_bottom_editor(bottom_control)


func _on_collection_changed(new_dict):
	emit_changed(get_edited_property(), new_dict, "", true)


func _update_property():
	current_value = get_edited_object()[get_edited_property()]
	property_control._on_value_changed(current_value)
	if property_control.collection_editor != null:
		property_control.stored_collection = current_value
		property_control.collection_editor.display(current_value, plugin)
