extends Control 

const CONFIRMATION_SCENE = preload("res://scenes/ui/ConfirmationWindow.tscn")

@onready var scene_manager = get_node("/root/Main/SceneManager")
@onready var save_window = $SaveWindow 
@onready var continue_button = %ContinueButton 

func _ready() -> void:
	AudioManager.play_music("music/no-place-to-go-216744")
	check_continue_availability()

func does_any_save_exist() -> bool:
	for i in range(1, 4):
		if FileAccess.file_exists("user://save_slot_%d.json" % i):
			return true
	return false

func check_continue_availability():
	continue_button.disabled = !does_any_save_exist()

func _on_continue_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	save_window.open_save_window(true)

# --- ZMIANY TUTAJ ---

func _on_new_game_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	
	if does_any_save_exist():
		spawn_confirmation_window()
	else:
		start_fresh_game()

func spawn_confirmation_window():
	var popup = CONFIRMATION_SCENE.instantiate()
	add_child(popup)
	popup.confirmed.connect(start_fresh_game)

func start_fresh_game():
	print("Rozpoczynam nową grę (kasowanie starych zapisów)...")
	var dir = DirAccess.open("user://")
	if dir:
		for i in range(1, 4): 
			var file_path = "save_slot_%d.json" % i
			if dir.file_exists(file_path):
				dir.remove(file_path)
				print("Usunięto zapis: ", file_path)
	
	GameState.reset_new_game(1)
	
	SceneManager.goto_lvl("level_01")


func _on_settings_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	scene_manager.goto_settings()

func _on_quit_button_pressed():
	AudioManager.play_ui_sound("ui/click")
	get_tree().quit()
