class_name DictionaryInspectorPlugin
extends EditorInspectorPlugin

var plugin


func _init(plugin):
	self.plugin = plugin


func can_handle(object):
	return true


func parse_property(object, type, path, hint, hint_text, usage):
	if type in [
		TYPE_DICTIONARY, TYPE_ARRAY,
		TYPE_RAW_ARRAY, TYPE_INT_ARRAY, TYPE_REAL_ARRAY, TYPE_STRING_ARRAY,
		TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_COLOR_ARRAY
	]:
		add_property_editor(path, DictionaryInspectorProperty.new(object[path], plugin))
		return true

	else:
			return false
