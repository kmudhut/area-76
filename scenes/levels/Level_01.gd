extends Node2D

func _on_finish_level_button_pressed():
	var scene_manager = get_node("/root/Main/SceneManager")
	scene_manager.goto_scene("res://EndScreen.tscn")
