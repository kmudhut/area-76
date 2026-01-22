extends Area2D

# --- KONFIGURACJA W INSPEKTORZE ---
# Wpisz tekst tutaj. Używaj klamer {} do oznaczania akcji.
# Przykład: "Użyj {left}{right} aby chodzić, wciśnij {jump} by skoczyć."
@export_multiline var text: String = "Tekst samouczka"
@export var fade_duration: float = 0.5
@export var one_shot: bool = true
@export var detection_radius: float = 150.0
# Ścieżki do ikon (Upewnij się, że masz te foldery!)
const KEYBOARD_PATH = "res://assets/input_prompts/Keyboard & Mouse/Default/"
const XBOX_PATH = "res://assets/input_prompts/Xbox Series/Default/"

@onready var label = $RichTextLabel
@onready var collision_shape = $CollisionShape2D
# Zmienne stanu
var has_been_read = false
var using_gamepad = false 

func _ready():
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.radius = detection_radius

	# Konfiguracja Labela
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.fit_content = true
	label.custom_minimum_size = Vector2(200, 0)
	label.modulate.a = 0.0
	
	# Tło (czarne, półprzezroczyste)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.4) 
	style.set_corner_radius_all(8)
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 5; style.content_margin_bottom = 5
	label.add_theme_stylebox_override("normal", style)
	
	# Sygnały wejścia/wyjścia gracza
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Sprawdzenie początkowe - czy pad jest podłączony?
	if Input.get_connected_joypads().size() > 0:
		using_gamepad = true
	
	await get_tree().process_frame
	update_text()

# --- WYKRYWANIE ZMIANY URZĄDZENIA (Input) ---
func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		if using_gamepad:
			using_gamepad = false
			update_text()
	elif event is InputEventJoypadButton:
		if not using_gamepad:
			using_gamepad = true
			update_text() 
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.3:
			if not using_gamepad:
				using_gamepad = true
				update_text()

func update_text():
	label.text = parse_text(text)

# --- LOGIKA FADE IN/OUT ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		if one_shot and has_been_read: return
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, fade_duration)
		has_been_read = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 0.0, fade_duration)

# --- PARSOWANIE TEKSTU ---
func parse_text(raw_text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\{([a-zA-Z0-9_]+)\\}")
	
	var result = raw_text
	for match_result in regex.search_all(raw_text):
		var placeholder = match_result.get_string() 
		var token = match_result.get_string(1) 
		
		var icon_path = get_icon_path(token)
		
		if icon_path != "":
			result = result.replace(placeholder, "[img=32]" + icon_path + "[/img]")
		else:
			# Fallback: Jeśli nie ma ikony, wyświetl czerwony tekst
			result = result.replace(placeholder, "[color=red]" + token.to_upper() + "[/color]")
			
	return "[center]" + result + "[/center]"

# --- GŁÓWNA LOGIKA DOBIERANIA IKON ---
func get_icon_path(token: String) -> String:
	var direct = get_direct_xbox_icon(token)
	if direct != "": return direct
	
	return get_input_map_icon(token)

func get_input_map_icon(action: String) -> String:
	if not InputMap.has_action(action): return ""
	var events = InputMap.action_get_events(action)
	
	# --- TRYB PADA ---
	if using_gamepad:
		for event in events:
			if event is InputEventJoypadButton:
				return get_xbox_icon_by_index(event.button_index)
			if event is InputEventJoypadMotion:
				return get_xbox_icon_by_axis(event.axis, event.axis_value)

	# --- TRYB KLAWIATURY (Domyślny lub gdy using_gamepad == false) ---
	# Szukamy klawisza przypisanego do tej akcji
	for event in events:
		if event is InputEventKey:
			var key_str = OS.get_keycode_string(event.physical_keycode).to_lower()
			if key_str == "space": key_str = "space" # Fix dla spacji
			return check_path(KEYBOARD_PATH + "keyboard_" + key_str + ".png")
			
	return ""

# --- MAPOWANIE: PAD (OSIE / GAŁKI) ---
func get_xbox_icon_by_axis(axis: int, value: float) -> String:
	var fname = ""
	match axis:
		JOY_AXIS_LEFT_X:
			if value < 0: fname = "xbox_stick_l_left.png"
			elif value > 0: fname = "xbox_stick_l_right.png"
			else: fname = "xbox_stick_l_horizontal.png"
		JOY_AXIS_LEFT_Y:
			if value < 0: fname = "xbox_stick_l_up.png"
			elif value > 0: fname = "xbox_stick_l_down.png"
			else: fname = "xbox_stick_l_vertical.png"
		JOY_AXIS_RIGHT_X:
			if value < 0: fname = "xbox_stick_r_left.png"
			elif value > 0: fname = "xbox_stick_r_right.png"
		JOY_AXIS_RIGHT_Y:
			if value < 0: fname = "xbox_stick_r_up.png"
			elif value > 0: fname = "xbox_stick_r_down.png"
			
	var path = check_path(XBOX_PATH + fname)
	if path != "": return path
	
	# Fallback do ogólnej gałki
	if axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_LEFT_Y:
		return check_path(XBOX_PATH + "xbox_stick_l.png")
	return ""

# --- MAPOWANIE: PAD (PRZYCISKI) ---
func get_xbox_icon_by_index(idx) -> String:
	var fname = ""
	match idx:
		JOY_BUTTON_A: fname = "xbox_button_a.png"
		JOY_BUTTON_B: fname = "xbox_button_b.png"
		JOY_BUTTON_X: fname = "xbox_button_x.png"
		JOY_BUTTON_Y: fname = "xbox_button_y.png"
		JOY_BUTTON_LEFT_SHOULDER: fname = "xbox_lb.png"
		JOY_BUTTON_RIGHT_SHOULDER: fname = "xbox_rb.png"
		JOY_BUTTON_START: fname = "xbox_button_menu.png"
		JOY_BUTTON_BACK: fname = "xbox_button_view.png"
		JOY_BUTTON_LEFT_STICK: fname = "xbox_stick_l_click.png"
		JOY_BUTTON_RIGHT_STICK: fname = "xbox_stick_r_click.png"
		JOY_BUTTON_DPAD_UP: fname = "xbox_dpad_up.png"
		JOY_BUTTON_DPAD_DOWN: fname = "xbox_dpad_down.png"
		JOY_BUTTON_DPAD_LEFT: fname = "xbox_dpad_left.png"
		JOY_BUTTON_DPAD_RIGHT: fname = "xbox_dpad_right.png"
	
	if fname != "": return check_path(XBOX_PATH + fname)
	return ""

# --- MAPOWANIE: PAD (BEZPOŚREDNIE NAZWY) ---
func get_direct_xbox_icon(token: String) -> String:
	var t = token.to_lower()
	var fname = ""
	match t:
		"lb": fname = "xbox_lb.png"
		"rb": fname = "xbox_rb.png"
		"lt": fname = "xbox_lt.png"
		"rt": fname = "xbox _rt.png"
		"a": fname = "xbox_button_a.png"
		"b": fname = "xbox_button_b.png"
		"x": fname = "xbox_button_x.png"
		"y": fname = "xbox_button_y.png"
		"start": fname = "xbox_button_menu.png"
		"select": fname = "xbox_button_view.png"
	
	if fname != "": return check_path(XBOX_PATH + fname)
	return ""

func check_path(path: String) -> String:
	if ResourceLoader.exists(path): return path
	return ""
