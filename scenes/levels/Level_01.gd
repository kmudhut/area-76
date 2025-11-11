extends Node2D
func _ready() -> void:
	AudioManager.play_music("music/big-jason-slap-house-background-music-for-video-vlog-stories-short-394175")
func _on_finish_level_button_pressed():
	var scene_manager = get_node("/root/Main/SceneManager")
	scene_manager.goto_scene("res://EndScreen.tscn")
