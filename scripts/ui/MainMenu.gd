extends Control 

@onready var scene_manager = get_node("/root/Main/SceneManager")
@onready var save_window = $SaveWindow 
@onready var continue_button = %ContinueButton 

func _ready() -> void:
	AudioManager.play_music("music/no-place-to-go-216744")
	
	# Sprawdzamy, czy istnieją jakiekolwiek zapisy, by aktywować przycisk Kontynuuj
	# (Opcjonalne, ale estetyczne)
	check_continue_availability()

func check_continue_availability():
	var save_exists = false
	for i in range(1, 4):
		if FileAccess.file_exists("user://save_slot_%d.json" % i):
			save_exists = true
			break
	
	continue_button.disabled = !save_exists
	# Jeśli wolisz, żeby był zawsze aktywny (bo SaveWindow pokaże puste sloty),
	# to zakomentuj powyższe i odkomentuj to:
	# continue_button.disabled = false

func _on_continue_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	# Tutaj nadal otwieramy okno slotów, żeby gracz wybrał co wczytać
	save_window.open_save_window(true)

func _on_new_game_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	
	# --- NOWA LOGIKA: KASOWANIE WSZYSTKIEGO I START ---
	
	# 1. Usuwamy pliki zapisów (Slot 1, 2, 3...)
	var dir = DirAccess.open("user://")
	if dir:
		for i in range(1, 4): # Zakładamy 3 sloty
			var file_path = "save_slot_%d.json" % i
			if dir.file_exists(file_path):
				dir.remove(file_path)
				print("Usunięto zapis: ", file_path)
	
	# 2. Resetujemy stan gry na domyślnym Slocie 1
	# To stworzy nowy, czysty plik save_slot_1.json
	GameState.reset_new_game(1)
	
	# 3. Uruchamiamy pierwszy poziom bezpośrednio
	SceneManager.goto_lvl("level_01")

func _on_settings_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	scene_manager.goto_settings()

func _on_quit_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	get_tree().quit()
