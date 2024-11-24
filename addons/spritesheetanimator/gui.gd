@tool
extends Control

@onready var spritebox = $ScrollContainer/VBoxContainer/HBoxContainer/SpriteScroll/SpriteSelection
@onready var directionsbox = $ScrollContainer/VBoxContainer/HBoxContainer/DirectionsScroll/Directions
@onready var animbox = $ScrollContainer/VBoxContainer/HBoxContainer/AnimationsScroll/Animations
@onready var savebox = $ScrollContainer/VBoxContainer/HBoxContainer/SaveScroll
@onready var settingbutton = $ScrollContainer/VBoxContainer/HBoxContainer/SaveScroll/Settings

var animPlayer: AnimationPlayer
var directions = []
var animations = {}
var sprites = []
var update_anims = true
var overwrite_tracks = false
var save_path = "res://addons/spritesheetanimator/save.json"
var save_dict = {}

func _ready():
	savebox.get_node("Animate").pressed.connect(generate)
	animbox.get_node("More").pressed.connect(add_animation_option)
	directionsbox.get_node("More").pressed.connect(add_direction_option)
	savebox.get_node("Save").pressed.connect(save_settings)
	savebox.get_node("H/Delete").pressed.connect(delete_settings)
	savebox.get_node("H/Load").pressed.connect(load_setting)
	setup_sprite_options()
	load_file()
	
func generate():
	directions = []
	animations = {}
	sprites = []
	get_directions()
	get_animations()
	get_selected_sprites()
	check_frame_count()
	if spritebox.get_node("Existing").selected == 0:
		update_anims = true
	else:
		update_anims = false
	overwrite_tracks = spritebox.get_node("Tracks").is_pressed()
	var library
	if animPlayer.has_animation_library(""):
		library = animPlayer.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		animPlayer.add_animation_library("", library)
	var layout = spritebox.get_node("Layout").selected
	var start_frame = 0
	var frame_increment = 1
	if layout == 1:
		frame_increment = directions.size()
	for direction in directions:
		if layout == 1:
			start_frame = directions.find(direction)
		for animation in animations:
			var dict = animations[animation]
			if not library.has_animation(animation + "_" + direction) or update_anims:
				add_animation(start_frame, dict['frames'], dict['increment'], dict['looping'],
					library, animation, direction, frame_increment)
			start_frame += dict['frames'] * frame_increment

func get_directions() -> void:
	directions = []
	for direction in directionsbox.get_node("V").get_children():
		if not direction.text.is_empty():
			directions.append(direction.get_text())
		
func get_animations() -> void:
	var counter = 1
	for hbox in animbox.get_node("V").get_children():
		if not hbox.get_node("AnimationName").text.is_empty():
			var anim_name = hbox.get_node("AnimationName").get_text()
			animations[anim_name] = {} 
			animations[anim_name]['frames'] = hbox.get_node("NumFrames").get_value()
			animations[anim_name]['increment'] = hbox.get_node("Increment").get_value()
			animations[anim_name]['looping'] = int(hbox.get_node("Looping").get_selected())
			animations[anim_name]['order'] = counter # for loading
			counter += 1
			if animations[anim_name]['frames'] == 0 or animations[anim_name]['increment'] == 0:
				animations.erase(anim_name)
				counter -= 1

# Find all sprite nodes in the scene
func setup_sprite_options() -> void:
	var root = EditorInterface.get_edited_scene_root()
	var all_nodes = get_all_children(root)
	for node in all_nodes:
		if node is Sprite2D:
			spritebox.get_node("V").add_child(create_sprite_option(node.name))

# recursively list all children
func get_all_children(in_node, array := []) -> Array:
	array.push_back(in_node)
	for child in in_node.get_children():
		array = get_all_children(child, array)
	return array
	
func create_sprite_option(sprite_name) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	var gui = EditorInterface.get_base_control()
	var load_icon = gui.get_theme_icon("Sprite2D", "EditorIcons")
	var icon = TextureRect.new()
	icon.texture = load_icon
	var label = Label.new()
	label.text = sprite_name
	var check = CheckBox.new()
	check.button_pressed = true
	hbox.add_child(check)
	hbox.add_child(icon)
	hbox.add_child(label)
	return(hbox)

func get_selected_sprites() -> void:
	var root = EditorInterface.get_edited_scene_root()
	for hbox in spritebox.get_node("V").get_children():
		if hbox is HBoxContainer:
			if hbox.get_children()[0].button_pressed:
				var sprite_name = hbox.get_children()[2].text
				sprites.append(root.find_child(sprite_name))

func add_animation_option() -> void:
	var details = load("res://addons/spritesheetanimator/animation_details.tscn").instantiate()
	animbox.get_node("V").add_child(details)

func add_direction_option():
	var direction = LineEdit.new()
	directionsbox.get_node("V").add_child(direction)
	
# make sure each selected sprite has enough frames for the listed animations
func check_frame_count() -> void:
	var anim_frames = 0
	for animation in animations:
		anim_frames += animations[animation]['frames']
	var required_frames = anim_frames * directions.size()
	for sprite in sprites:
		var sprite_frames = sprite.hframes * sprite.vframes
		assert(sprite_frames >= required_frames,
			"Sprite %s has fewer than the required number of frames" % sprite.name)

func add_animation(start_frame: int, num_frames: int, increment: float, loop_mode: int,
	library: AnimationLibrary, animation_name: String, direction: String,
	frame_increment = 1) -> void:
	var anim
	if library.has_animation(animation_name + "_" + direction):
		anim = library.get_animation(animation_name + "_" + direction)
	else:
		anim = Animation.new()
	for sprite in sprites:
		var track_index
		if not overwrite_tracks and library.has_animation(animation_name + "_" + direction):
			# remove only the track for sprite frames
			track_index = anim.find_track(sprite.name + ":frame", 0)
			anim.remove_track(track_index)
		track_index = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_index, sprite.name + ":frame")
		anim.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
		var track_time = 0.0
		for frame in num_frames:
			anim.track_insert_key(track_index, track_time, start_frame + frame * frame_increment)
			track_time += increment
	anim.loop_mode = loop_mode
	anim.length = num_frames * increment
	library.add_animation(animation_name + "_" + direction, anim)

func delete_settings():
	if settingbutton.get_selected_id() == -1:
		return
	var id = settingbutton.get_selected_id()
	var idx = settingbutton.get_item_index(id)
	save_dict.erase(settingbutton.get_item_text(idx))
	settingbutton.remove_item(idx)
	save_file()

func save_settings():
	if savebox.get_node("SaveName").text.is_empty():
		return
	var setting_name = savebox.get_node("SaveName").text
	var item_num = settingbutton.item_count
	for item in item_num:
		var idx = settingbutton.get_item_index(item)
		if settingbutton.get_item_text(idx) == setting_name:
			settingbutton.remove_item(idx)
	settingbutton.add_item(setting_name)
	get_directions()
	get_animations()
	# re order for loading
	var out_animations = {}
	for animation_name in animations:
		var anim = animations[animation_name]
		out_animations[anim['order']] = anim
		out_animations[anim['order']]['name'] = animation_name
	save_dict[setting_name] = {
		"layout": spritebox.get_node("Layout").get_selected_id(),
		"existing": spritebox.get_node("Existing").get_selected_id(),
		"tracks": spritebox.get_node("Tracks").is_pressed(),
		"directions": directions,
		"animations": out_animations
	}
	save_file()
	
func save_file():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var json = JSON.stringify(save_dict)
	file.store_line(json)

func load_file():
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return
	if file == null:
		return
	if FileAccess.file_exists(save_path):
		if not file.eof_reached():
			var current_line = JSON.parse_string(file.get_line())
			if current_line:
				save_dict = current_line
	for option in save_dict:
		settingbutton.add_item(option)

func load_setting():
	var setting_id = settingbutton.get_selected_id()
	var setting_idx = settingbutton.get_item_index(setting_id)
	var setting_name = settingbutton.get_item_text(setting_idx)
	var sett = save_dict[setting_name]
	var layout_idx = spritebox.get_node("Layout").get_item_index(sett['layout'])
	spritebox.get_node("Layout").select(layout_idx)
	var existing_idx = spritebox.get_node("Existing").get_item_index(sett['existing'])
	spritebox.get_node("Existing").select(existing_idx)
	spritebox.get_node("Tracks").set_pressed(sett['tracks'])
	for direction in directionsbox.get_node("V").get_children():
		direction.queue_free()
	for direction in sett['directions']:
		var line = LineEdit.new()
		line.text = direction
		directionsbox.get_node("V").add_child(line)
	for animation in animbox.get_node("V").get_children():
		animation.queue_free()
	var details_scene = load("res://addons/spritesheetanimator/animation_details.tscn")
	for i in sett['animations']:
		var animation = sett['animations'][i]
		var details = details_scene.instantiate()
		details.get_node("AnimationName").text = animation['name']
		details.get_node("NumFrames").value = animation['frames']
		details.get_node("Increment").value = animation['increment']
		var idx = details.get_node("Looping").get_item_index(animation['looping'])
		details.get_node("Looping").select(idx)
		animbox.get_node("V").add_child(details)
	
