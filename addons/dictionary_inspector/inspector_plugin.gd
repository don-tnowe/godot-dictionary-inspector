extends EditorInspectorPlugin

const supported_types = [
	TYPE_DICTIONARY,
	TYPE_ARRAY,
	TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY
]

var plugin


func _init(plugin):
	self.plugin = plugin


func _can_handle(object):
	return true


func _parse_property(object, type, path, hint, hint_text, usage, wide) -> bool:
	if object != null:
		if path in object:
			var value = object[path]
			if !typeof(value) in supported_types:
				return false

			if value is Array:
				# Block some Array types, since the built-in editor will be better
				if hint == PROPERTY_HINT_ENUM || hint_text.left(hint_text.find(":")).split("/").has(str(PROPERTY_HINT_ENUM)):
					return false

			add_property_editor(path, load("res://addons/dictionary_inspector/inspector_property.gd").new(object[path], plugin))
			return true
	return false
