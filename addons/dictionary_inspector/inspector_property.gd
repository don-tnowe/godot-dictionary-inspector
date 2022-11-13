tool
class_name DictionaryInspectorProperty
extends EditorProperty

var property_control = Button.new()
var bottom_control = DictPropertyEditor.new()
var current_value : Dictionary

var plugin : EditorPlugin


func _init(plugin):
	self.plugin = plugin
	add_child(property_control)
	add_focusable(property_control)

	add_child(bottom_control)
	set_bottom_editor(bottom_control)
	bottom_control.hide()

	property_control.connect("pressed", self, "_on_button_pressed")
	bottom_control.connect("value_changed", self, "_on_dictionary_changed")


func _on_button_pressed():
	# plugin.dialog.display(get_edited_object(), get_edited_property(), plugin)
	bottom_control.visible = !bottom_control.visible
	if bottom_control.get_child_count() < 2:
		bottom_control.display(current_value, plugin)


func _on_dictionary_changed(new_dict):
	emit_changed(get_edited_property(), new_dict)


func update_property():
	current_value = get_edited_object()[get_edited_property()]
	property_control.text = "Dictionary (size " + str(current_value.size()) + ")"
