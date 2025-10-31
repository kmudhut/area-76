extends Control

func _on_new_game_button_pressed() -> void:
	# 1. Find our SceneManager in the Main scene
	var scene_manager = get_node("/root/Main/SceneManager")
	
	# 2. Tell it to load the first level scene
	#    Make sure you have a level scene at this path!
	scene_manager.goto_scene("res://scenes/levels/Level_01.tscn")


func _on_quit_button_pressed() -> void:
	# This function could stay, but it's better to use the SceneManager too
	get_node("/root/Main/SceneManager").quit_game()
