@tool
extends EditorPlugin

var plugin


func _enter_tree():
	plugin = load("res://addons/dictionary_inspector/inspector_plugin.gd").new(self)
	add_custom_type("DictionaryInspectorArrayIndex", "Button", load("res://addons/dictionary_inspector/elements/special_buttons/array_index.gd"), null)
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_inspector_plugin(plugin)
