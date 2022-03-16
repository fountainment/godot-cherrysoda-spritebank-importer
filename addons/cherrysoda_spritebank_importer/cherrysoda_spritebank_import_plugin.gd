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


func get_frames(path):
	var frames = []
	var index = 0
	var dir = Directory.new()
	var single_file = "res://textures/%s.png" % [path]
	if dir.file_exists(single_file):
		return [single_file]
	while true:
		var s = str(index).length()
		var found = false
		for i in range(s, 5):
			var format_string = "res://textures/%s%0" + str(i) + "d.png"
			var file_name = format_string % [path, index]
			if dir.file_exists(file_name):
				frames.append(file_name)
				found = true
				break
		if not found:
			break
		index += 1
	return frames


func get_animation(animatedSprite, id, fps, frame_count, loop):
	var animation = Animation.new()
	var start_track_id = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_interpolation_type(start_track_id, Animation.INTERPOLATION_NEAREST)
	animation.track_set_path(start_track_id, "AnimatedSprite:animation")
	animation.track_insert_key(start_track_id, 0, id)
	var track_id = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_interpolation_type(track_id, Animation.INTERPOLATION_NEAREST)
	animation.track_set_path(track_id, "AnimatedSprite:frame")
	for i in frame_count:
		animation.track_insert_key(track_id, i / fps, i)
	animation.set_length(frame_count / fps)
	animation.set_loop(loop)
	return animation


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
		var useIdForDefaultAnimationPath = sprite.has("UseIdForDefaultAnimationPath")
		animatedSprite.frames = spriteFrames
		scene.add_child(node)
		node.set_owner(scene)
		node.add_child(animatedSprite)
		node.add_child(animationPlayer)
		animatedSprite.set_owner(scene)
		animationPlayer.set_owner(scene)
		
		spriteFrames.remove_animation("default")
		
		var default_fps = round(1.0 / float(sprite.delay))
		var start_animation = str(sprite.start)
		var sprite_path = str(sprite.path)

		if sprite.has("Anim"):
			for anim in sprite.Anim:
				var fps = default_fps
				if anim.has("delay"):
					fps = round(1.0 / float(anim.delay))
				spriteFrames.add_animation(anim.id)
				spriteFrames.set_animation_loop(anim.id, false)
				spriteFrames.set_animation_speed(anim.id, fps)
				var anim_path = ""
				if useIdForDefaultAnimationPath:
					anim_path = anim.id
				if anim.has("path"):
					anim_path = anim.path
				var frames = get_frames(sprite_path + anim_path)
				for frame in frames:
					var texture = load(frame)
					spriteFrames.add_frame(anim.id, texture)
				var animation = get_animation(animatedSprite, anim.id, fps, frames.size(), false)
				animationPlayer.add_animation(anim.id, animation)
				if anim.id == start_animation:
					animatedSprite.animation = anim.id
					animationPlayer.current_animation = anim.id
		
		if sprite.has("Loop"):
			for anim in sprite.Loop:
				var fps = default_fps
				if anim.has("delay"):
					fps = round(1.0 / float(anim.delay))
				spriteFrames.add_animation(anim.id)
				spriteFrames.set_animation_loop(anim.id, true)
				spriteFrames.set_animation_speed(anim.id, fps)
				var anim_path = ""
				if useIdForDefaultAnimationPath:
					anim_path = anim.id
				if anim.has("path"):
					anim_path = anim.path
				var frames = get_frames(sprite_path + anim_path)
				for frame in frames:
					var texture = load(frame)
					spriteFrames.add_frame(anim.id, texture)
				var animation = get_animation(animatedSprite, anim.id, fps, frames.size(), true)
				animationPlayer.add_animation(anim.id, animation)
				if anim.id == start_animation:
					animatedSprite.animation = anim.id
					animationPlayer.current_animation = anim.id


	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)

	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)
