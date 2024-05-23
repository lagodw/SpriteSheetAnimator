@tool
extends EditorPlugin

var tab
var animPlayer: AnimationPlayer
var sprites = []

func _enter_tree():
	var editor_selection = get_editor_interface().get_selection()
	editor_selection.connect("selection_changed", _on_selection_changed)

func _exit_tree():
	remove_tab()

func remove_tab():
	if tab:
		remove_control_from_bottom_panel(tab)
		tab.queue_free()
		tab = null

func _on_selection_changed():
	var editor_selection = get_editor_interface().get_selection()
	var selected_objects = editor_selection.get_selected_nodes()
	remove_tab()
	if selected_objects.size() > 0 and selected_objects[0] is AnimationPlayer:
		tab = load("res://addons/spritesheetanimator/gui.tscn").instantiate()
		tab.animPlayer = selected_objects[0]
		add_control_to_bottom_panel(tab, "SpriteSheet")
	else:
		animPlayer = null
