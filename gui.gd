@tool
extends Control

@onready var spritebox = $ScrollContainer/VBoxContainer/HBoxContainer/SpriteScroll/SpriteSelection
@onready var directionsbox = $ScrollContainer/VBoxContainer/HBoxContainer/DirectionsScroll/Directions
@onready var animbox = $ScrollContainer/VBoxContainer/HBoxContainer/AnimationsScroll/Animations

var animPlayer: AnimationPlayer
var directions = []
var animations = []
var sprites = []

func _ready():
	$ScrollContainer/VBoxContainer/Animate.pressed.connect(generate)
	animbox.get_node("MoreAnimations").pressed.connect(add_animation_option)
	directionsbox.get_node("MoreDirections").pressed.connect(add_direction_option)
	setup_sprite_options()
	for i in range(4):
		add_animation_option()
	
func generate():
	directions = get_directions()
	animations = get_animations()
	sprites = get_selected_sprites()
	var library = AnimationLibrary.new()
	var start_frame = 0
	for direction in directions:
		for animation in animations:
			var dict = animations[animation]
			add_animation(start_frame, dict['frames'], dict['increment'], 
				library, animation, direction)
			start_frame += dict['frames']
	animPlayer.add_animation_library("", library)
	print(animPlayer.get_animation_list())
	animPlayer.play(animPlayer.get_animation_list()[0])

func get_directions() -> Array:
	var directions = []
	for direction in directionsbox.get_children():
		if direction is LineEdit:
			directions.append(direction.get_text())
	return(directions)
		
func get_animations() -> Dictionary:
	var animations = {}
	for hbox in animbox.get_children():
		# Ignore label and button
		if hbox is HBoxContainer:
			var anim_name = hbox.get_node("AnimationName").get_text()
			animations[anim_name] = {} 
			animations[anim_name]['frames'] = int(hbox.get_node("NumFrames").get_text())
			animations[anim_name]['increment'] = float(hbox.get_node("Increment").get_text())
			animations[anim_name]['looping'] = int(hbox.get_node("Looping").get_selected())
	return(animations)

func add_animation(start_frame: int, num_frames: int, increment: float, 
	library: AnimationLibrary, animation_name: String, direction: String) -> void:
	var anim = Animation.new()
	for sprite in sprites:
		var track_index = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_index, sprite.name + ":frame")
		var track_time = 0.0
		for frame in num_frames:
			anim.track_insert_key(track_index, track_time, start_frame + frame)
			track_time += increment
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = num_frames * increment
	library.add_animation(animation_name + "_" + direction, anim)

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

func get_selected_sprites() -> Array:
	var sprites = []
	var root = EditorInterface.get_edited_scene_root()
	for hbox in spritebox.get_children():
		if hbox is HBoxContainer:
			if hbox.get_children()[0].button_pressed:
				var sprite_name = hbox.get_children()[2].text
				sprites.append(root.find_child(sprite_name))
	return(sprites)

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
	
