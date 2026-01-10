extends CanvasLayer

const setting_scene = preload("res://scenes/ui/SettingsPauseMenu.tscn")
var setting_scene_instance = null

func _ready() -> void:
	# Ważne: Menu pauzy musi działać, gdy gra jest zatrzymana
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("pause") and SceneManager.get_active_scene().is_in_group("gameplayScene")):
		if GameState.is_usos_active:
			return
		
		# Logika: Jeśli otwarte są ustawienia, ESC je zamyka.
		# Jeśli nie, ESC wznawia grę.
		if setting_scene_instance != null:
			_close_settings()
		else:
			toggle_pause_game()

func toggle_pause_game() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	self.visible = new_pause_state
	
	# Jeśli wznawiamy grę, upewnij się, że zamykamy też okno ustawień (jeśli było otwarte)
	if not new_pause_state and setting_scene_instance != null:
		setting_scene_instance.queue_free()
		setting_scene_instance = null

func _on_resume_button_pressed() -> void:
	AudioManager.play_ui_sound("ui/click")
	toggle_pause_game()

func _on_exit_to_main_menu_button_pressed() -> void:
	print("--- KLIKNIĘTO WYJŚCIE DO MENU ---")
	AudioManager.play_ui_sound("ui/click")
	
	toggle_pause_game()
	AudioManager.stop_music()
	
	print("Wysyłam żądanie do SceneManager...")
	SceneManager.goto_menu()

func _on_settings_button_pressed() -> void:
	AudioManager.play_ui_sound("ui/click")
	
	# Zabezpieczenie przed otwarciem dwóch okien naraz
	if setting_scene_instance == null:
		setting_scene_instance = setting_scene.instantiate()
		add_child(setting_scene_instance)
		
		# Opcjonalnie: Ukryj przyciski pauzy, gdy settings są na wierzchu
		# $Control.visible = false 

func _on_restart_level_button_pressed() -> void:
	print("--- KLIKNIĘTO RESTART ---")
	AudioManager.play_ui_sound("ui/click")
	
	# 1. Odpauzowanie
	toggle_pause_game()
	print("Gra odpauzowana")
	
	# 2. Reset danych
	GameState.restart_level_data()
	print("Dane zresetowane. Aktualny poziom w GameState: ", GameState.current_level_name)
	
	# 3. Budowanie ścieżki
	var level_name = GameState.current_level_name
	# Zabezpieczenie przed podwójnym .tscn
	level_name = level_name.replace(".tscn", "") 
	
	print("Próbuję wczytać poziom: ", level_name)
	SceneManager.goto_lvl(level_name)

# Funkcja pomocnicza do zamykania ustawień
func _close_settings():
	if setting_scene_instance != null:
		setting_scene_instance.queue_free()
		setting_scene_instance = null
		# Jeśli ukrywałeś przyciski pauzy, tutaj je przywróć:
		# $Control.visible = true
