tool
extends EditorPlugin


var import_plugin = null


func get_name():
	return "CherrySoda SpriteBank Importer"


func _enter_tree():
	import_plugin = preload("cherrysoda_spritebank_import_plugin.gd").new()
	add_import_plugin(import_plugin)


func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null
