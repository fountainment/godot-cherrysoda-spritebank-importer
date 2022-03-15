tool
extends EditorImportPlugin


enum Presets { DEFAULT }


func get_importer_name():
	return "cherrysoda_spritebank_importer"


func get_visible_name():
	return "SpriteBank from CherrySoda"


func get_recognized_extensions():
	return ["json"]


func get_save_extension():
	return "scn"


func get_priority():
	return 1


func get_import_order():
	return 100


func get_resource_type():
	return "PackedScene"


func get_preset_count():
	return Presets.size()


func get_preset_name(preset):
	match preset:
		Presets.DEFAULT: return "Default"


func get_import_options(preset):
	match preset:
		Presets.DEFAULT:
			return [{
					   "name": "use_red_anyway",
					   "default_value": false
					}]
		_:
			return []


func get_option_visibility(option, options):
	return true


func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var scene = Node2D.new()
	scene.set_name("Sprites")

	var f = File.new()
	var err = f.open(source_file, File.READ)
	if err != OK:
		return err
 
	var json_res = JSON.parse(f.get_as_text())
	if json_res.error != OK:
		return json_res.error

	var ts = json_res.result
	for sprite in ts.Sprites:
		var node = Node2D.new()
		node.set_name(str(sprite.Name))
		var animatedSprite = AnimatedSprite.new()
		var animationPlayer = AnimationPlayer.new()
		var spriteFrames = SpriteFrames.new()
		animatedSprite.frames = spriteFrames
		scene.add_child(node)
		node.set_owner(scene)
		node.add_child(animatedSprite)
		node.add_child(animationPlayer)
		animatedSprite.set_owner(scene)
		animationPlayer.set_owner(scene)
		
		spriteFrames.remove_animation("default")
		
		var default_fps = round(1.0 / float(sprite.delay))

		if sprite.has("Anim"):
			for anim in sprite.Anim:
				var fps = default_fps
				if anim.has("delay"):
					fps = round(1.0 / float(anim.delay))
				spriteFrames.add_animation(anim.id)
				spriteFrames.set_animation_loop(anim.id, false)
				spriteFrames.set_animation_speed(anim.id, fps)
		
		if sprite.has("Loop"):
			for anim in sprite.Loop:
				var fps = default_fps
				if anim.has("delay"):
					fps = round(1.0 / float(anim.delay))
				spriteFrames.add_animation(anim.id)
				spriteFrames.set_animation_loop(anim.id, true)
				spriteFrames.set_animation_speed(anim.id, fps)
		
		

	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)

	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)
