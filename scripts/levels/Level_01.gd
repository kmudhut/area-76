extends Node2D

@onready var end_screen = $EndScreen

func _ready() -> void:
	GameState.current_level_name = "Level_01"
	GameState.game_over.connect(_on_game_over)
	GameState.reset_new_game()
	AudioManager.play_music("music/big-jason-slap-house-background-music-for-video-vlog-stories-short-394175")
	
func _on_finish_level_button_pressed():
	var scene_manager = get_node("/root/Main/SceneManager")
	scene_manager.goto_scene("res://EndScreen.tscn")

func _on_game_over():
	GameState.is_usos_active = true # blokowanie ekranu pauzy
	print("Gracz umarł!")
	if end_screen:
		await get_tree().create_timer(1.0).timeout
		end_screen.setup_game_over_screen()
		end_screen.visible = true
