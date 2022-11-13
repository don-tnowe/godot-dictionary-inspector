tool
extends EditorPlugin

var plugin = DictionaryInspectorPlugin.new(self)


func _enter_tree():
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_inspector_plugin(plugin)
