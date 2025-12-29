extends CanvasLayer

# --- REFERENCJE DO UI ---
# Paski i Monety
@onready var motivation_bar = $MotivationContainer/VBoxContainer/MotivationBar
@onready var motivation_label = $MotivationContainer/VBoxContainer/MotivationLabel
@onready var ects_label = $CoinContainer/CoinLabel

# --- SEKJA LLM ---
@onready var llm_container = $LLM_PowerUpContainer
@onready var llm_label = $LLM_PowerUpContainer/LLM_Label
@onready var llm_icon = $LLM_PowerUpContainer/LLM_PowerUpIcon 

# --- KONFIGURACJA ---
var llm_text_template = "Wciśnij {bumper_left}+{bumper_right}, aby zapytać Bota. Odpowiedź może być zmyślona, ale brzmi tak mądrze, że przeciwnicy zgłupieją."
var using_gamepad = false
var damage_tween: Tween
var bar_tween: Tween
var coin_tween: Tween

# Ścieżki do ikon
const KEYBOARD_PATH = "res://assets/input_prompts/Keyboard & Mouse/Default/"
const XBOX_PATH = "res://assets/input_prompts/Xbox Series/Default/"

func _ready():
	llm_container.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.4) 
	style.set_corner_radius_all(14)
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 5; style.content_margin_bottom = 5
	llm_label.add_theme_stylebox_override("normal", style)
	
	# Podłączanie sygnałów
	if not GameState.ects_changed.is_connected(update_ects):
		GameState.ects_changed.connect(update_ects)
	
	if not GameState.motivation_changed.is_connected(update_motivation):
		GameState.motivation_changed.connect(update_motivation)

	# Inicjalizacja UI
	update_ects(GameState.ects)
	update_motivation(GameState.motivation, GameState.max_motivation)
	
	if Input.get_connected_joypads().size() > 0:
		using_gamepad = true

# --- WYKRYWANIE ZMIANY URZĄDZENIA ---
func _input(event):
	var changed = false
	if event is InputEventKey or event is InputEventMouseButton:
		if using_gamepad:
			using_gamepad = false
			changed = true
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if (event is InputEventJoypadMotion and abs(event.axis_value) < 0.3): return
		if not using_gamepad:
			using_gamepad = true
			changed = true
			
	if changed and llm_container.visible:
		update_llm_text_display()

# --- GŁÓWNA FUNKCJA POKAZUJĄCA MOC LLM ---
func show_llm_powerup(has_item: bool):
	if not has_item:
		llm_container.visible = false
		return

	llm_container.visible = true
	llm_container.modulate.a = 1.0 
	llm_label.visible = true
	llm_label.modulate.a = 1.0
	update_llm_text_display()

# --- SYSTEM IKON (PARSOWANIE) ---
func update_llm_text_display():
	llm_label.text = parse_text(llm_text_template)

func parse_text(raw_text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\{([a-zA-Z0-9_]+)\\}")
	
	var result = raw_text
	for match_result in regex.search_all(raw_text):
		var placeholder = match_result.get_string()
		var token = match_result.get_string(1)
		var icon_path = get_input_map_icon(token)
		
		if icon_path != "":
			result = result.replace(placeholder, "[img=500]" + icon_path + "[/img]")
		else:
			result = result.replace(placeholder, "[color=red]" + token.to_upper() + "[/color]")
	return result

func get_input_map_icon(action: String) -> String:
	if not InputMap.has_action(action): return ""
	var events = InputMap.action_get_events(action)
	var found_icon_path = ""
	
	if using_gamepad:
		found_icon_path = find_gamepad_icon(events)
	else:
		found_icon_path = find_keyboard_icon(events)
	
	if found_icon_path == "":
		found_icon_path = find_gamepad_icon(events)
		
	return found_icon_path

func find_keyboard_icon(events) -> String:
	for event in events:
		if event is InputEventKey:
			var key_str = OS.get_keycode_string(event.physical_keycode).to_lower()
			if key_str == "space": key_str = "space"
			var path = KEYBOARD_PATH + "keyboard_" + key_str + ".png"
			if ResourceLoader.exists(path): return path
	return ""

func find_gamepad_icon(events) -> String:
	for event in events:
		if event is InputEventJoypadButton:
			return get_xbox_icon_by_index(event.button_index)
	return ""

func get_xbox_icon_by_index(idx) -> String:
	var fname = ""
	match idx:
		JOY_BUTTON_LEFT_SHOULDER: fname = "xbox_lb.png"
		JOY_BUTTON_RIGHT_SHOULDER: fname = "xbox_rb.png"
	if fname != "": return check_path(XBOX_PATH + fname)
	return ""

func check_path(path: String) -> String:
	if ResourceLoader.exists(path): return path
	return ""

# --- FUNKCJE MOTYWACJI I ECTS ---

func update_ects(new_ects):
	ects_label.text = str(new_ects) + "/30"
	var target_node = $CoinContainer 
	
	if coin_tween:
		coin_tween.kill()
		
	coin_tween = create_tween()
	
	coin_tween.tween_property(target_node, "scale", Vector2(0.12, 0.12), 0.05)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	coin_tween.tween_property(target_node, "scale", Vector2(0.1, 0.1), 0.12)

func update_motivation(current_val, max_val):
	var previous_val = motivation_bar.value if motivation_bar else 0
	
	if motivation_bar:
		motivation_bar.max_value = max_val
		if bar_tween:
			bar_tween.kill()
		
		bar_tween = create_tween()
		bar_tween.tween_property(motivation_bar, "value", current_val, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if motivation_label:
		var curr_txt = str(int(current_val))
		var max_txt = str(int(max_val))
		motivation_label.text = "MOTYWACJA: " + curr_txt + "/" + max_txt
	
	# Mignięcie na biało przy otrzymaniu obrażeń
	if current_val < previous_val:
		flash_damage()

# NOWE: Efekt mignięcia paska na biało
func flash_damage():
	if damage_tween:
		damage_tween.kill()
	
	damage_tween = create_tween()
	
	# Mignij na biało
	damage_tween.tween_property(motivation_bar, "modulate", Color(1, 0, 0), 0.1)
	
	# Wróć do normalnego koloru (Biały w modulate oznacza "oryginalny kolor paska")
	damage_tween.tween_property(motivation_bar, "modulate", Color(1, 1, 1, 1), 0.3)
