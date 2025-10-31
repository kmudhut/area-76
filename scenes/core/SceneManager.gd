extends Node

@export var scene_container : Node

var current_scene = null

func _ready():
	goto_main_menu()

func goto_scene(scene_path):
	if current_scene:
		current_scene.queue_free()

	var scene = load(scene_path)
	if not scene:
		print("Error: Could not load scene: ", scene_path)
		return

	current_scene = scene.instantiate()
	scene_container.add_child(current_scene)

func goto_main_menu():
	goto_scene("res://scenes/ui/MainMenu.tscn") 

func quit_game():
	get_tree().quit()
