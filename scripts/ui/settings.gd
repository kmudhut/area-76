extends Control
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

var current_difficulty_index:int;
const difficulty_levels = ["Łatwy", "Normalny", "Trudny"]

var current_screen_mode_index;
const screen_modes = [	{"displayed_name":"Okno", "value":"window"}, 
						{"displayed_name":"Pełny ekran", "value":"fullscreen"}
					];

var current_resolution_index;
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
	];

func _ready() -> void:
	difficulty_label.text=difficulty_levels[UserPreferences.get_setting("general", "difficulty_level")]
	current_difficulty_index=int(UserPreferences.get_setting("general", "difficulty_level"))
	
	var screen_mode_val = UserPreferences.get_setting("graphics", "screen_mode");
	for i in range(screen_modes.size()):
		if screen_modes[i]["value"] == screen_mode_val:
			screen_mode_label.text = screen_modes[i].displayed_name;
			current_screen_mode_index = i;
			break 
			
	var resolution_val = UserPreferences.get_setting("graphics", "resolution");
	for i in range(screen_resolutions.size()):
		if screen_resolutions[i]["value"] == resolution_val:
			resolution_label.text = screen_resolutions[i].displayed_name;
			current_resolution_index = i;
			break 
			
	main_volume_label.text = String.num(UserPreferences.get_setting("audio", "main_volume")*100,0)
	main_volume_slider.value = UserPreferences.get_setting("audio", "main_volume")*100
	
	interface_volume_label.text = String.num(UserPreferences.get_setting("audio", "interface_volume")*100,0)
	interface_volume_slider.value = UserPreferences.get_setting("audio", "interface_volume")*100
	
	sfx_volume_label.text = String.num(UserPreferences.get_setting("audio", "sfx_volume")*100,0)
	sfx_volume_slider.value = UserPreferences.get_setting("audio", "sfx_volume")*100
	
	music_volume_label.text = String.num(UserPreferences.get_setting("audio", "music_volume")*100,0)
	music_volume_slider.value = UserPreferences.get_setting("audio", "music_volume")*100

func _on_return_button_pressed() -> void:
	get_node("/root/Main/SceneManager").goto_main_menu()


func _on_difficulty_left_arrow_pressed() -> void:
	if(current_difficulty_index>0):
		current_difficulty_index-=1
		UserPreferences.set_setting("general", "difficulty_level", int(current_difficulty_index))
		difficulty_label.text = difficulty_levels[current_difficulty_index]
		difficulty_right_button.disabled = false
		
		if(current_difficulty_index==0):
			difficulty_left_button.disabled = true
		
func _on_difficulty_right_arrow_pressed() -> void:
	if(current_difficulty_index<difficulty_levels.size()-1):
		current_difficulty_index+=1
		UserPreferences.set_setting("general", "difficulty_level", int(current_difficulty_index))
		difficulty_label.text = difficulty_levels[current_difficulty_index]
		difficulty_left_button.disabled = false
		
		if(current_difficulty_index==difficulty_levels.size()-1):
			difficulty_right_button.disabled = true


func _on_screen_mode_left_button_pressed() -> void:
	if(current_screen_mode_index>0):
		current_screen_mode_index-=1
		UserPreferences.set_setting("graphics", "screen_mode", screen_modes[current_screen_mode_index]["value"])
		screen_mode_label.text = screen_modes[current_screen_mode_index]["displayed_name"];
		screen_mode_right_button.disabled = false
		
		if(current_screen_mode_index==0):
			screen_mode_left_button.disabled = true

func _on_screen_mode_right_button_pressed() -> void:
	if(current_screen_mode_index<screen_modes.size()-1):
		current_screen_mode_index+=1
		UserPreferences.set_setting("graphics", "screen_mode", screen_modes[current_screen_mode_index]["value"])
		screen_mode_label.text = screen_modes[current_screen_mode_index]["displayed_name"];
		screen_mode_left_button.disabled = false
		
		if(current_screen_mode_index==screen_modes.size()-1):
			screen_mode_right_button.disabled = true


func _on_resolution_left_button_pressed() -> void:
	if(current_resolution_index > 0):
		current_resolution_index-=1
		UserPreferences.set_setting("graphics", "resolution", screen_resolutions[current_resolution_index]["value"])
		resolution_label.text = screen_resolutions[current_resolution_index]["displayed_name"];
		resolution_right_button.disabled = false
		
		if(current_resolution_index==0):
			resolution_left_button.disabled = true

func _on_resolution_right_button_pressed() -> void:
	if(current_resolution_index < screen_resolutions.size()-1):
		current_resolution_index+=1
		UserPreferences.set_setting("graphics", "resolution", screen_resolutions[current_resolution_index]["value"])
		resolution_label.text = screen_resolutions[current_resolution_index]["displayed_name"];
		resolution_left_button.disabled = false
		
		if(current_resolution_index==screen_resolutions.size()-1):
			resolution_right_button.disabled = true


func _on_main_volume_slider_value_changed(value: float) -> void:
	UserPreferences.set_setting("audio", "main_volume", value/100.0)
	main_volume_label.text = String.num(value,0)
	
func _on_interface_volume_slider_value_changed(value: float) -> void:
	UserPreferences.set_setting("audio", "interface_volume", value/100.0)
	interface_volume_label.text = String.num(value,0)
	
func _on_sfx_volume_slider_value_changed(value: float) -> void:
	UserPreferences.set_setting("audio", "sfx_volume", value/100.0)
	sfx_volume_label.text = String.num(value,0)
	
func _on_music_volume_slider_value_changed(value: float) -> void:
	UserPreferences.set_setting("audio", "music_volume", value/100.0)
	music_volume_label.text = String.num(value,0)
	
