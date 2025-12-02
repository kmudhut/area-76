extends CanvasLayer
const setting_scene = preload("res://scenes/ui/SettingsPauseMenu.tscn")
var setting_scene_instance
func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("pause") and SceneManager.get_active_scene().is_in_group("gameplayScene")):
			toggle_pause_game()
		
func toggle_visibility() -> void:
	self.visible = not self.visible
	
func toggle_pause_game() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	self.visible = new_pause_state
	if(setting_scene_instance):
		self.remove_child(setting_scene_instance)
	
func _on_resume_button_pressed() -> void:
	toggle_pause_game() 


func _on_exit_to_main_menu_button_pressed() -> void:
	toggle_pause_game()
	AudioManager.stop_music()
	SceneManager.goto_menu();
	


func _on_settings_button_pressed() -> void:
	#self.get_node("ColorRect").visible = false
	setting_scene_instance = setting_scene.instantiate()
	self.add_child(setting_scene_instance)


func _on_restart_level_button_pressed() -> void:
	toggle_pause_game()
	GameState.ects = 0
	SceneManager.goto_lvl("Level_01.tscn")
