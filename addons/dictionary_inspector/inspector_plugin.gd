class_name DictionaryInspectorPlugin
extends EditorInspectorPlugin

var plugin


func _init(plugin):
	self.plugin = plugin


func can_handle(object):
	return true


func parse_property(object, type, path, hint, hint_text, usage):
	if type == TYPE_DICTIONARY:
		add_property_editor(path, DictionaryInspectorProperty.new(plugin))
		return true

	else:
			return false
