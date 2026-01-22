extends Control

# Referencje do UI (zostawiamy bez zmian)
@onready var difficulty_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/Label
@onready var difficulty_left_button: TextureButton = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/TextureButton
@onready var difficulty_right_button: TextureButton = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/TextureButton2
@onready var screen_mode_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer/Label
@onready var screen_mode_left_button: TextureButton = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer/TextureButton
@onready var screen_mode_right_button: TextureButton = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer/TextureButton2
@onready var resolution_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer2/VBoxContainer/VBoxContainer2/HBoxContainer/Label
@onready var resolution_left_button: TextureButton = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer2/VBoxContainer/VBoxContainer2/HBoxContainer/TextureButton
@onready var resolution_right_button: TextureButton = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer2/VBoxContainer/VBoxContainer2/HBoxContainer/TextureButton2
@onready var main_volume_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer/HBoxContainer/Label
@onready var main_volume_slider: HSlider = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer/HBoxContainer/HSlider
@onready var interface_volume_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer2/HBoxContainer/Label
@onready var interface_volume_slider: HSlider = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer2/HBoxContainer/HSlider
@onready var sfx_volume_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer3/HBoxContainer/Label
@onready var sfx_volume_slider: HSlider = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer3/HBoxContainer/HSlider
@onready var music_volume_label: Label = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer4/HBoxContainer/Label
@onready var music_volume_slider: HSlider = $PanelContainer/SettingsContainer/HBoxContainer/MarginContainer3/VBoxContainer/VBoxContainer4/HBoxContainer/HSlider

var current_difficulty_index: int
const difficulty_levels = ["Łatwy", "Normalny", "Trudny"]

var current_screen_mode_index
const screen_modes = [	{"displayed_name":"Okno", "value":"window"}, 
						{"displayed_name":"Pełny ekran", "value":"fullscreen"}
					]

var current_resolution_index
const screen_resolutions = [
	{"displayed_name":"1366 x 768", "value":"1366x768"}, 
	{"displayed_name":"1440 x 900", "value":"1440x900"}, 
	{"displayed_name":"1440 x 1080", "value":"1440x1080"},
	{"displayed_name":"1600 x 900", "value":"1600x900"},
	{"displayed_name":"1600 x 1024", "value":"1600x1024"},
	{"displayed_name":"1680 x 1050", "value":"1680x1050"},	
	{"displayed_name":"1768 x 992", "value":"1768x992"},
	{"displayed_name":"1920 x 1080", "value":"1920x1080"},
	{"displayed_name":"2560 × 1440", "value":"2560x1440"},
	]
	
func _ready() -> void:
	self.get_parent().get_node('ColorRect').visible = false
	# --- SEKCJA TRUDNOŚCI ---
	# 1. Pobieramy ustawienie z pliku konfiguracyjnego (UserPreferences)
	current_difficulty_index = int(UserPreferences.get_setting("general", "difficulty_level"))
	difficulty_label.text = difficulty_levels[current_difficulty_index]
	
	# 2. Aktualizujemy stan przycisków
	update_difficulty_buttons()
	
	# 3. WAŻNE: Synchronizujemy to z GameState na starcie
	# Dzięki temu GameState wie, jaki poziom trudności wczytać
	update_gamestate_difficulty()
	
	# --- RESZTA USTAWIEŃ (Grafika, Audio) ---
	var screen_mode_val = UserPreferences.get_setting("graphics", "screen_mode")
	for i in range(screen_modes.size()):
		if screen_modes[i]["value"] == screen_mode_val:
			screen_mode_label.text = screen_modes[i].displayed_name
			current_screen_mode_index = i
			break 
			
	var resolution_val = UserPreferences.get_setting("graphics", "resolution")
	for i in range(screen_resolutions.size()):
		if screen_resolutions[i]["value"] == resolution_val:
			resolution_label.text = screen_resolutions[i].displayed_name
			current_resolution_index = i
			break 
			
	setup_slider(main_volume_slider, main_volume_label, "main_volume")
	setup_slider(interface_volume_slider, interface_volume_label, "interface_volume")
	setup_slider(sfx_volume_slider, sfx_volume_label, "sfx_volume")
	setup_slider(music_volume_slider, music_volume_label, "music_volume")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		self.get_parent().get_node('ColorRect').visible = true
		queue_free()
		get_viewport().set_input_as_handled()
		
# Funkcja pomocnicza do suwaków (czystszy kod)
func setup_slider(slider, label, setting_name):
	var val = UserPreferences.get_setting("audio", setting_name) * 100
	label.text = String.num(val, 0)
	slider.value = val

		
func _on_return_button_pressed() -> void:
	AudioManager.play_ui_sound("ui/click")
	self.get_parent().get_node('ColorRect').visible = true
	queue_free()
	
# --- ZMIANA TRUDNOŚCI ---

func _on_difficulty_left_arrow_pressed() -> void:
	if current_difficulty_index > 0:
		AudioManager.play_ui_sound("ui/click")
		current_difficulty_index -= 1
		apply_difficulty_change()

func _on_difficulty_right_arrow_pressed() -> void:
	if current_difficulty_index < difficulty_levels.size() - 1:
		AudioManager.play_ui_sound("ui/click")
		current_difficulty_index += 1
		apply_difficulty_change()

func apply_difficulty_change():
	# 1. Zapis do UserPreferences (Dysk)
	UserPreferences.set_setting("general", "difficulty_level", int(current_difficulty_index))
	
	# 2. Aktualizacja UI
	difficulty_label.text = difficulty_levels[current_difficulty_index]
	update_difficulty_buttons()
	
	# 3. Aktualizacja GameState (Logika gry)
	update_gamestate_difficulty()

func update_difficulty_buttons():
	difficulty_left_button.disabled = (current_difficulty_index == 0)
	difficulty_right_button.disabled = (current_difficulty_index == difficulty_levels.size() - 1)

# --- ŁĄCZNIK Z GAMESTATE ---
func update_gamestate_difficulty():
	# Przekazujemy indeks (0=Easy, 1=Normal, 2=Hard) do GameState
	# GameState automatycznie zmapuje to na enum Difficulty
	if has_node("/root/GameState"):
		get_node("/root/GameState").current_difficulty = current_difficulty_index
		print("Ustawiono poziom trudności w GameState na: ", difficulty_levels[current_difficulty_index])

# --- OBSŁUGA GRAFIKI (Bez większych zmian, tylko refactor) ---

func _on_screen_mode_left_button_pressed() -> void:
	change_screen_mode(-1)

func _on_screen_mode_right_button_pressed() -> void:
	change_screen_mode(1)

func change_screen_mode(direction):
	if (direction == -1 and current_screen_mode_index > 0) or (direction == 1 and current_screen_mode_index < screen_modes.size() - 1):
		AudioManager.play_ui_sound("ui/click")
		current_screen_mode_index += direction
		var mode_data = screen_modes[current_screen_mode_index]
		UserPreferences.set_setting("graphics", "screen_mode", mode_data["value"])
		screen_mode_label.text = mode_data["displayed_name"]
		
		screen_mode_left_button.disabled = (current_screen_mode_index == 0)
		screen_mode_right_button.disabled = (current_screen_mode_index == screen_modes.size() - 1)

func _on_resolution_left_button_pressed() -> void:
	change_resolution(-1)

func _on_resolution_right_button_pressed() -> void:
	change_resolution(1)

func change_resolution(direction):
	if (direction == -1 and current_resolution_index > 0) or (direction == 1 and current_resolution_index < screen_resolutions.size() - 1):
		AudioManager.play_ui_sound("ui/click")
		current_resolution_index += direction
		var res_data = screen_resolutions[current_resolution_index]
		UserPreferences.set_setting("graphics", "resolution", res_data["value"])
		resolution_label.text = res_data["displayed_name"]
		
		resolution_left_button.disabled = (current_resolution_index == 0)
		resolution_right_button.disabled = (current_resolution_index == screen_resolutions.size() - 1)

# --- OBSŁUGA AUDIO ---

func _on_main_volume_slider_value_changed(value: float) -> void:
	update_volume("main_volume", value, main_volume_label)
	
func _on_interface_volume_slider_value_changed(value: float) -> void:
	update_volume("interface_volume", value, interface_volume_label)
	
func _on_sfx_volume_slider_value_changed(value: float) -> void:
	update_volume("sfx_volume", value, sfx_volume_label)
	
func _on_music_volume_slider_value_changed(value: float) -> void:
	update_volume("music_volume", value, music_volume_label)

func update_volume(setting_name, value, label):
	UserPreferences.set_setting("audio", setting_name, value / 100.0)
	label.text = String.num(value, 0)
