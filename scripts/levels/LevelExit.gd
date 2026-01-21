extends Area2D

# --- KONFIGURACJA W INSPEKTORZE ---
@export_file("*.tscn") var next_level_scene: String
@export_multiline var text_locked: String = "[center][color=#ff5555]⛔ DOSTĘP ZABLOKOWANY[/color]\n[font_size=20]Wymagane uprawnienia: 12 ECTS[/font_size]\nSTATUS: [color=#ff5555]{points} ECTS[/color][/center]"
@export_multiline var text_conditional: String = "[center][color=#ffff55]⚠ DOSTĘP WARUNKOWY[/color]\n[font_size=20]Ryzyko niezaliczenia wykryte.[/font_size]\n[wave amp=20 freq=5][color=#ffff55][Wciśnij {jump}][/color][/wave][/center]"
@export_multiline var text_perfect: String = "[center][color=#55ff55]✔ DOSTĘP PRZYZNANY[/color]\n[font_size=20]Student Wzorowy.[/font_size]\n[rainbow freq=0.5][Wciśnij {jump}][/rainbow][/center]"

# --- ZMIENNE WEWNĘTRZNE ---
@onready var label = $RichTextLabel
@onready var door_sprite = $DoorSprite 

var player_in_range = false
var can_exit = false
var using_gamepad = false
var tween: Tween
var min_ects: int = 12
var max_ects: int = 30
var reader_offset: Vector2 = Vector2(100, 20)
var label_shift_x: float = 100.0

# Ścieżki do ikon
const KEYBOARD_PATH = "res://assets/input_prompts/Keyboard & Mouse/Default/"
const XBOX_PATH = "res://assets/input_prompts/Xbox Series/Default/"

func _ready():
	if get_node_or_null("/root/GameState"):
		if not GameState.ects_changed.is_connected(_on_ects_changed):
			GameState.ects_changed.connect(_on_ects_changed)
	update_status()
	label.bbcode_enabled = true
	label.visible = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.fit_content = true
	label.custom_minimum_size = Vector2(250, 0) 
	
	# --- STYL HOLOGRAMU ---
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.1, 0.85) 
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.8, 1.0, 0.6)
	style.border_blend = false
	style.set_corner_radius_all(4)
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 8; style.content_margin_bottom = 8
	label.add_theme_stylebox_override("normal", style)
	
	# Podłączenie sygnałów
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if Input.get_connected_joypads().size() > 0:
		using_gamepad = true
		
	if door_sprite:
		door_sprite.play("closed")
		
	update_status()
		
func _on_ects_changed(_new_value):
	update_status()

func _process(_delta):
	if player_in_range and can_exit:
		if Input.is_action_just_pressed("jump"):
			enter_next_level()
			
	if label.visible:
		queue_redraw()

# --- RYSOWANIE LINII ŁĄCZĄCEJ (Wiązka światła) ---
func _draw():
	if label.visible:
		# Punkt startowy: Czytnik (z uwzględnieniem offsetu)
		var start_pos = reader_offset
		var end_pos = label.position + Vector2(label.size.x / 2, label.size.y)
		
		# Rysujemy linię
		draw_line(start_pos, end_pos, Color(0.0, 0.8, 1.0, 0.6), 2.0)
		
		# Rysujemy małą kropkę na czytniku (źródło)
		draw_circle(start_pos, 3.0, Color(0.0, 0.478, 1.0, 1.0))

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		update_status()
		show_label()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_label()

# --- ANIMACJE HOLOGRAMU ---
func recenter_label():
	# Ustawiamy punkt obrotu na środek
	label.pivot_offset = Vector2(label.size.x / 2, label.size.y)
	
	# Obliczamy nową pozycję, żeby dymek był wycentrowany nad czytnikiem
	var target_y = reader_offset.y - label.size.y - 60
	var target_x = (reader_offset.x - (label.size.x / 2)) + label_shift_x
	label.position = Vector2(target_x, target_y)

func show_label():
	label.visible = true
	await get_tree().process_frame
	recenter_label()
	
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	label.scale = Vector2(0, 0)
	tween.tween_property(label, "scale", Vector2(1, 1), 0.25)
	
	queue_redraw()

func hide_label():
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(0, 0), 0.15)
	tween.tween_callback(func(): 
		label.visible = false
		queue_redraw() # Wyczyść linię po zniknięciu
	)

func update_status():
	var current_ects = 0
	if get_node_or_null("/root/GameState"):
		current_ects = GameState.ects
	
	var final_text = ""
	
	var open_door_offset = Vector2(-72, 0) 
	
	if current_ects < min_ects:
		can_exit = false
		final_text = text_locked.replace("{points}", str(current_ects))
		if door_sprite: 
			door_sprite.play("closed")
			door_sprite.offset = Vector2.ZERO # Resetujemy przesunięcie!
		
	elif current_ects < max_ects:
		can_exit = true
		final_text = text_conditional.replace("{points}", str(current_ects))
		if door_sprite: 
			door_sprite.play("slightly")
			door_sprite.offset = Vector2.ZERO # Resetujemy przesunięcie!
		
	else:
		can_exit = true
		final_text = text_perfect.replace("{points}", str(current_ects))
		if door_sprite: 
			door_sprite.play("opened")
			# Tlko tutaj dodajemy przesunięcie
			door_sprite.offset = open_door_offset 
	
	label.text = parse_text_icons(final_text)

func enter_next_level():
	print("Próba wejścia do: ", next_level_scene)
	
	if next_level_scene == "":
		printerr("BŁĄD: Nie przypisano sceny w Inspektorze!")
		return

	if get_node_or_null("/root/SceneManager"):
		SceneManager.goto_lvl(next_level_scene)

# --- SYSTEM IKON ---
func parse_text_icons(raw_text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\{([a-zA-Z0-9_]+)\\}")
	var result = raw_text
	for match_result in regex.search_all(raw_text):
		var placeholder = match_result.get_string()
		var token = match_result.get_string(1)
		if token == "points": continue
		var icon_path = get_icon_path(token)
		if icon_path != "":
			# Mniejsza ikona (24px) żeby pasowała do tekstu hologramu
			result = result.replace(placeholder, "[img=24]" + icon_path + "[/img]")
		else:
			result = result.replace(placeholder, "[color=yellow]" + token.to_upper() + "[/color]")
	return result

func get_icon_path(action: String) -> String:
	if not InputMap.has_action(action): return ""
	var events = InputMap.action_get_events(action)
	if using_gamepad:
		for event in events:
			if event is InputEventJoypadButton: return get_xbox_icon(event.button_index)
	for event in events:
		if event is InputEventKey:
			var key = OS.get_keycode_string(event.physical_keycode).to_lower()
			if key == "space": key = "space"
			return check_path(KEYBOARD_PATH + "keyboard_" + key + ".png")
	return ""

func get_xbox_icon(idx) -> String:
	var f = ""
	match idx:
		JOY_BUTTON_A: f = "xbox_button_a.png"
		JOY_BUTTON_B: f = "xbox_button_b.png"
		JOY_BUTTON_X: f = "xbox_button_x.png"
		JOY_BUTTON_Y: f = "xbox_button_y.png"
		JOY_BUTTON_DPAD_UP: f = "xbox_dpad_up.png"
	if f != "": return check_path(XBOX_PATH + f)
	return ""

func check_path(p): return p if ResourceLoader.exists(p) else ""
