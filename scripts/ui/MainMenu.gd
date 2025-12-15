extends Control # Lub CanvasLayer, zależnie od Twojej sceny

@onready var scene_manager = get_node("/root/Main/SceneManager")
@onready var continue_button = %ContinueButton 

func _ready() -> void:
	AudioManager.play_music("music/no-place-to-go-216744")
	
	# Sprawdzamy czy jest plik zapisu. Jeśli tak -> włącz przycisk.
	if FileAccess.file_exists(GameState.SAVE_FILE):
		continue_button.disabled = false
		continue_button.visible = true
	else:
		continue_button.disabled = true
		continue_button.visible = false

func _on_continue_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	
	# 1. Wczytujemy dane do GameState
	if GameState.load_game():
		print("Wczytano zapis! Poziom: ", GameState.current_level_name)
		
		# 2. Budujemy ścieżkę do poziomu
		# Zakładam, że GameState trzyma np. "Level_01" (dzięki kodowi z Kroku 1)
		var level_name = GameState.current_level_name
		level_name=level_name.to_lower()
		# UWAGA: Tu wpisz dokładną ścieżkę do folderu z Twoimi poziomami!
		# Jeśli masz je w "res://scenes/levels/", to zostaw tak jak jest.
		var full_path =  level_name + ".tscn"
		
		# 3. Sprawdzamy czy plik sceny istnieje (dla bezpieczeństwa)
		if ResourceLoader.exists(full_path):
			scene_manager.goto_lvl(full_path)
		else:
			print("BŁĄD: Nie znaleziono sceny: ", full_path)
			# Awaryjnie spróbuj załadować samą nazwę (jeśli SceneManager to obsługuje)
			scene_manager.goto_lvl(level_name + ".tscn")
	else:
		print("Błąd wczytywania pliku zapisu.")

func _on_new_game_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	GameState.reset_new_game()
	scene_manager.goto_lvl("Level_01.tscn")

func _on_settings_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	scene_manager.goto_settings()

func _on_quit_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	get_tree().quit()
