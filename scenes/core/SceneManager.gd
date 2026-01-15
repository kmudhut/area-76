extends Node

const CONTAINER_PATH = "/root/Main/SceneContainer"

const PATH_MENU 	  = "res://scenes/ui/MainMenu.tscn"
const PATH_SETTINGS	  = "res://scenes/ui/SettingsMenu.tscn"
const PATH_END 	 	  = "res://scenes/ui/EndScreen.tscn"
const PATH_LEVELS 	  = "res://scenes/levels/"

var current_scene: Node = null 
var last_level_path: String = ""
var fade_layer: ColorRect
var is_fading: bool = false
var fade_time := 0.4

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS 
	_create_fade_layer()
	
	if not has_node(CONTAINER_PATH):
		printerr("CRITICAL: Brak węzła: " + CONTAINER_PATH)
	else:
		print("SceneManager gotowy.")
		call_deferred("goto_menu")

func get_active_scene() -> Node:
	if is_instance_valid(current_scene):
		return current_scene
	
	var container = get_node_or_null(CONTAINER_PATH)
	if container and container.get_child_count() > 0:
		var real_scene = container.get_child(container.get_child_count() - 1)
		current_scene = real_scene 
		return real_scene
		
	return null

func goto_scene(scene_path: String) -> void:
	if is_fading: return
	
	if get_tree().paused:
		get_tree().paused = false
		
	is_fading = true
	await _fade_out()
	
	var container = get_node_or_null(CONTAINER_PATH)
	
	if container == null:
		printerr("CRITICAL ERROR: Nie znaleziono kontenera: " + CONTAINER_PATH)
		is_fading = false
		return

	current_scene = null 
	for child in container.get_children():
		child.queue_free()
	print("goto_scene", scene_path,".")
	if ResourceLoader.exists(scene_path):
		var new_scene_packed = load(scene_path)
		var new_scene = new_scene_packed.instantiate()
		
		if scene_path.begins_with(PATH_LEVELS):
			last_level_path = scene_path
			if not new_scene.is_in_group("gameplay"):
				new_scene.add_to_group("gameplay")
		
		container.add_child(new_scene)
		current_scene = new_scene
		print("Załadowano: ", new_scene.name)
	else:
		printerr("BŁĄD: Plik nie istnieje: " + scene_path)
	
	await _fade_in()
	is_fading = false

func goto_menu(): goto_scene(PATH_MENU)
func goto_settings(): goto_scene(PATH_SETTINGS)
func goto_end(): goto_scene(PATH_END)

func goto_lvl(level_name: String):
	level_name = level_name.replace(".tscn", "").to_lower()
	
	print("goto_lvl w scenemanager", PATH_LEVELS + level_name + ".tscn", level_name )
	goto_scene(PATH_LEVELS + level_name + ".tscn")

func goto_last_level():
	if last_level_path != "": goto_scene(last_level_path)

func _create_fade_layer():
	fade_layer = ColorRect.new()
	fade_layer.color = Color(0,0,0,0)
	fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	canvas.add_child(fade_layer)
	add_child(canvas)

func _fade_out():
	fade_layer.visible = true
	var tw = create_tween()
	tw.tween_property(fade_layer, "color:a", 1.0, fade_time)
	await tw.finished

func _fade_in():
	var tw = create_tween()
	tw.tween_property(fade_layer, "color:a", 0.0, fade_time)
	await tw.finished
	fade_layer.visible = false
