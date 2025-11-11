extends Node
@onready var pause_menu: Control = null

# ===========================================================
# Uproszczony SceneManager z fade-in/out i pauzą
# ===========================================================

var current_scene: Node = null
var last_level_path: String = ""
var fade_layer: ColorRect
var is_fading: bool = false
var fade_time := 0.4

var is_paused := false
var last_scene_path := ""

# Stałe
const PATH_MENU      = "res://scenes/ui/MainMenu.tscn"
const PATH_SETTINGS  = "res://scenes/ui/SettingsMenu.tscn"
const PATH_END       = "res://scenes/ui/EndScreen.tscn"
const PATH_LEVELS    = "res://scenes/levels/"
const PATH_PAUSE_MENU = "res://scenes/ui/PauseMenu.tscn"

# -----------------------------------------------------------
# Inicjalizacja
# -----------------------------------------------------------
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_fade_layer()
	print("SceneManager gotowy.")
	goto_menu()


# -----------------------------------------------------------
# Główna funkcja do zmiany scen
# -----------------------------------------------------------
func goto_scene(scene_path: String) -> void:
	if is_fading:
		return
	is_fading = true
	await _fade_out()

	if current_scene:
		current_scene.queue_free()

	var new_scene = load(scene_path).instantiate()
	add_child(new_scene)
	current_scene = new_scene

	# Jeśli to poziom gry — zapamiętaj ścieżkę
	if scene_path.begins_with(PATH_LEVELS):
		last_level_path = scene_path

	await _fade_in()
	is_fading = false
	print("Załadowano scenę:", new_scene.name)

# -----------------------------------------------------------
# Skróty (API)
# -----------------------------------------------------------
func goto_menu() -> void:
	goto_scene(PATH_MENU)

func goto_settings() -> void:
	goto_scene(PATH_SETTINGS)

func goto_end() -> void:
	goto_scene(PATH_END)

func goto_lvl(level_name: String) -> void:
	goto_scene(PATH_LEVELS + level_name)

func goto_last_level():
	if last_level_path != "":
		goto_scene(last_level_path)

# ===========================================================
# Pauza
# ===========================================================
func goto_pause() -> void:
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true
	_pause_all_audio()
	
	# dodaj menu jako nakładkę
	if not pause_menu:
		pause_menu = load(PATH_PAUSE_MENU).instantiate()
		add_child(pause_menu)
	
	pause_menu.show()


func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false
	_resume_all_audio()
	if pause_menu:
		pause_menu.hide()


# Toggle — jedno wywołanie do pauzy / wznowienia
func pause_toggle() -> void:
	if is_paused:
		resume_game()
	else:
		goto_pause()

# ===========================================================
# Fade-in / Fade-out
# ===========================================================
func _create_fade_layer():
	fade_layer = ColorRect.new()
	fade_layer.name = "FadeLayer"
	fade_layer.color = Color(0, 0, 0, 0)
	fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.anchor_left = 0
	fade_layer.anchor_top = 0
	fade_layer.anchor_right = 1
	fade_layer.anchor_bottom = 1
	add_child(fade_layer)

func _fade_out():
	fade_layer.visible = true
	var tween = create_tween()
	tween.tween_property(fade_layer, "color:a", 1.0, fade_time)
	await tween.finished

func _fade_in():
	var tween = create_tween()
	tween.tween_property(fade_layer, "color:a", 0.0, fade_time)
	await tween.finished

# ===========================================================
# Pauza audio
# ===========================================================
var paused_audio_players: Array[AudioStreamPlayer] = []

func _pause_all_audio():
	paused_audio_players.clear()
	var players = get_tree().get_nodes_in_group("music")
	for player in players:
		if player.playing:
			player.pause()
			paused_audio_players.append(player)

func _resume_all_audio():
	for player in paused_audio_players:
		if is_instance_valid(player):
			player.play()
	paused_audio_players.clear()

# ===========================================================
# Globalna obsługa klawiatury
# ===========================================================
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if current_scene:
			# Jeśli aktualna scena to poziom gry — włącz/wyłącz pauzę
			if current_scene.scene_file_path.begins_with(PATH_LEVELS):
				pause_toggle()
			# Jeśli aktualna scena to menu pauzy — zamknij je (czyli kontynuuj grę)
			elif current_scene.scene_file_path == PATH_PAUSE_MENU:
				resume_game()
