extends Node

@onready var pause_menu: Control = null

# ===========================================================
# SceneManager 4.5 - fade, pauza, audio
# ===========================================================

var current_scene: Node = null
var last_level_path: String = ""
var fade_layer: ColorRect
var is_fading: bool = false
var fade_time := 0.4
var is_paused := false

# Stałe ścieżek
const PATH_MENU      = "res://scenes/ui/MainMenu.tscn"
const PATH_SETTINGS  = "res://scenes/ui/SettingsMenu.tscn"
const PATH_END       = "res://scenes/ui/EndScreen.tscn"
const PATH_LEVELS    = "res://scenes/levels/"
const PATH_PAUSE_MENU = "res://scenes/ui/PauseMenu.tscn"

# ===========================================================
# INICJALIZACJA
# ===========================================================
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_fade_layer()
	print("SceneManager gotowy.")
	goto_menu()

# ===========================================================
# ZMIANA SCEN
# ===========================================================
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

	if scene_path.begins_with(PATH_LEVELS):
		last_level_path = scene_path

	await _fade_in()
	is_fading = false
	print("Załadowano scenę:", new_scene.name)

func goto_menu():
	goto_scene(PATH_MENU)

func goto_settings():
	goto_scene(PATH_SETTINGS)

func goto_end():
	goto_scene(PATH_END)

func goto_lvl(level_name: String):
	goto_scene(PATH_LEVELS + level_name)

func goto_last_level():
	if last_level_path != "":
		goto_scene(last_level_path)

# ===========================================================
# FADE
# ===========================================================
func _create_fade_layer():
	fade_layer = ColorRect.new()
	fade_layer.color = Color(0,0,0,0)
	fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.anchor_left = 0
	fade_layer.anchor_right = 1
	fade_layer.anchor_top = 0
	fade_layer.anchor_bottom = 1

	# Fade na wierzchu dzięki CanvasLayer
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(fade_layer)
	add_child(canvas)

func _fade_out():
	fade_layer.visible = true
	var tw = create_tween()
	tw.tween_property(fade_layer, "color:a", 1.0, fade_time)
	await tw.finished

func _fade_in():
	fade_layer.visible = true
	var tw = create_tween()
	tw.tween_property(fade_layer, "color:a", 0.0, fade_time)
	await tw.finished
	fade_layer.visible = false
