extends Control
@onready var scene_manager = get_node("/root/Main/SceneManager")

func _on_new_game_button_pressed():
	scene_manager.goto_lvl("Level_01.tscn")


func _on_settings_button_pressed():
	scene_manager.goto_settings()


func _on_quit_button_pressed():
	get_tree().quit()
