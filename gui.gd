extends Control

var animPlayer: AnimationPlayer
var sprites = []

func _ready():
	animPlayer = $AnimationPlayer
	sprites.append($Sprite2D)
	$Panel/Animate.pressed.connect(generate)
	
func generate():
	var num_directions = int($Panel/HBoxContainer/SpriteSelection/NumDirections.get_text())
	var directions = get_directions()
	var animations = get_animations()
	var library = AnimationLibrary.new()
	add_animation(0, 4, 0.1, library)
	animPlayer.add_animation_library("animations", library)
	animPlayer.play("animations/test")

func get_directions() -> Array:
	var directions = []
	for direction in $Panel/HBoxContainer/Directions.get_children():
		directions.append(direction.get_text())
	return(directions)
		
func get_animations() -> Dictionary:
	var animations = {}
	for anim_hbox in $Panel/HBoxContainer/Animations.get_children():
		if anim_hbox == HBoxContainer:
			animations['name'] = anim_hbox.get_node("AnimationName").get_text()
			animations['frames'] = int(anim_hbox.get_node("NumFrames").get_text())
			animations['increment'] = anim_hbox.get_node("Increment").get_text()
			animations['looping'] = anim_hbox.get_node("Looping").get_selected()
	return(animations)

func add_animation(start_frame: int, num_frames: int, increment: float, library: AnimationLibrary):
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
	library.add_animation("test", anim)

