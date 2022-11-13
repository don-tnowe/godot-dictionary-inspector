tool
class_name DictionaryInspectorProperty
extends EditorProperty

var property_control
var current_value : Dictionary

var plugin : EditorPlugin


func _init(current_value, plugin):
	self.current_value = current_value
	self.plugin = plugin

	property_control = CollectionHeaderButton.new(current_value, plugin)
	add_child(property_control)
	add_focusable(property_control)
	property_control.connect("bottom_control_available", self, "_on_bottom_control_available")
	property_control.connect("value_changed", self, "_on_dictionary_changed")


func _on_bottom_control_available(bottom_control):
	add_child(bottom_control)
	set_bottom_editor(bottom_control)


func _on_dictionary_changed(new_dict):
	emit_changed(get_edited_property(), new_dict)


func update_property():
	current_value = get_edited_object()[get_edited_property()]
