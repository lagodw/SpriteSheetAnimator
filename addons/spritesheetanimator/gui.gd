@tool
extends Control

@onready var spritebox = $ScrollContainer/VBoxContainer/HBoxContainer/SpriteScroll/SpriteSelection
@onready var directionsbox = $ScrollContainer/VBoxContainer/HBoxContainer/DirectionsScroll/Directions
@onready var animbox = $ScrollContainer/VBoxContainer/HBoxContainer/AnimationsScroll/Animations

var animPlayer: AnimationPlayer
var directions = []
var animations = {}
var sprites = []
var overwrite = true

func _ready():
	$ScrollContainer/VBoxContainer/Animate.pressed.connect(generate)
	animbox.get_node("More").pressed.connect(add_animation_option)
	directionsbox.get_node("More").pressed.connect(add_direction_option)
	setup_sprite_options()
	
func generate():
	directions = []
	animations = {}
	sprites = []
	get_directions()
	get_animations()
	get_selected_sprites()
	check_frame_count()
	if spritebox.get_node("Existing").selected == 0:
		overwrite = true
	else:
		overwrite = false
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
			if not library.has_animation(animation + "_" + direction) or overwrite:
				add_animation(start_frame, dict['frames'], dict['increment'], dict['looping'],
					library, animation, direction, frame_increment)
			start_frame += dict['frames'] * frame_increment


func get_directions() -> void:
	for direction in directionsbox.get_children():
		if direction is LineEdit:
			if not direction.text.is_empty():
				directions.append(direction.get_text())
		
func get_animations() -> void:
	for hbox in animbox.get_children():
		# Ignore header and button
		if hbox is HBoxContainer and hbox.name != "Header":
			if not hbox.get_node("AnimationName").text.is_empty():
				var anim_name = hbox.get_node("AnimationName").get_text()
				animations[anim_name] = {} 
				animations[anim_name]['frames'] = hbox.get_node("NumFrames").get_value()
				animations[anim_name]['increment'] = hbox.get_node("Increment").get_value()
				animations[anim_name]['looping'] = int(hbox.get_node("Looping").get_selected())
				if animations[anim_name]['frames'] == 0 or animations[anim_name]['increment'] == 0:
					animations.erase(anim_name)

# Find all sprite nodes in the scene
func setup_sprite_options() -> void:
	var root = EditorInterface.get_edited_scene_root()
	var all_nodes = get_all_children(root)
	for node in all_nodes:
		if node is Sprite2D:
			spritebox.add_child(create_sprite_option(node.name))

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
	for hbox in spritebox.get_children():
		if hbox is HBoxContainer:
			if hbox.get_children()[0].button_pressed:
				var sprite_name = hbox.get_children()[2].text
				sprites.append(root.find_child(sprite_name))

func add_animation_option() -> void:
	var details = load("res://addons/spritesheetanimator/animation_details.tscn").instantiate()
	animbox.add_child(details)
	# keep plus button on bottom, -1 for button and another -1 because counting starts at 0
	animbox.move_child(details, animbox.get_child_count() - 2)

func add_direction_option():
	var direction = LineEdit.new()
	directionsbox.add_child(direction)
	# keep plus button on bottom, -1 for button and another -1 because counting starts at 0
	directionsbox.move_child(direction, directionsbox.get_child_count() - 2)
	
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
	var anim = Animation.new()
	for sprite in sprites:
		var track_index = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_index, sprite.name + ":frame")
		anim.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
		var track_time = 0.0
		for frame in num_frames:
			anim.track_insert_key(track_index, track_time, start_frame + frame * frame_increment)
			track_time += increment
	anim.loop_mode = loop_mode
	anim.length = num_frames * increment
	library.add_animation(animation_name + "_" + direction, anim)
