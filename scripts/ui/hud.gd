extends CanvasLayer

# --- REFERENCJE DO UI ---
# Paski i Monety
@onready var motivation_bar = $MotivationContainer/MotivationBar
@onready var ects_label = $CoinContainer/CoinLabel

# --- SEKJA LLM (Tutaj była zmiana) ---
# Teraz używamy tylko kontenera i jego dzieci (Ikony i Tekstu)
@onready var llm_container = $LLM_PowerUpContainer
@onready var llm_label = $LLM_PowerUpContainer/LLM_Label
@onready var llm_icon = $LLM_PowerUpContainer/LLM_PowerUpIcon 

# --- KONFIGURACJA TEKSTU ---
# Tekst z Twoimi ustawieniami (Bumpery)
var llm_text_template = "Wciśnij {bumper_left}+{bumper_right}, aby zapytać Bota. Odpowiedź może być zmyślona, ale brzmi tak mądrze, że przeciwnicy zgłupieją."

var using_gamepad = false
var llm_hide_tween: Tween

# Ścieżki do ikon
const KEYBOARD_PATH = "res://assets/input_prompts/Keyboard & Mouse/Default/"
const XBOX_PATH = "res://assets/input_prompts/Xbox Series/Default/"

func _ready():
    # 1. UKRYWAMY CAŁY KONTENER LLM NA STARCIE
    # Dzięki temu ani ikona, ani tekst nie będą widoczne, dopóki nie zbierzesz przedmiotu
    llm_container.visible = false
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0.4) 
    style.set_corner_radius_all(14)
    style.content_margin_left = 10; style.content_margin_right = 10
    style.content_margin_top = 5; style.content_margin_bottom = 5
    llm_label.add_theme_stylebox_override("normal", style)
    
    # 2. PODŁĄCZANIE SYGNAŁÓW (Tylko te, które istnieją)
    if not GameState.ects_changed.is_connected(update_ects):
        GameState.ects_changed.connect(update_ects)
    
    if not GameState.motivation_changed.is_connected(update_motivation):
        GameState.motivation_changed.connect(update_motivation)
    
    # (Usunąłem Golden Drink, bo tego węzła już nie ma w Twoim drzewie)

    # 3. INICJALIZACJA UI
    update_ects(GameState.ects)
    update_motivation(GameState.motivation, GameState.max_motivation)
    
    # Sprawdzenie pada na starcie
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
            
    # Odśwież tekst tylko jeśli LLM jest widoczny
    if changed and llm_container.visible:
        update_llm_text_display()

# --- GŁÓWNA FUNKCJA POKAZUJĄCA MOC LLM ---
func show_llm_powerup(has_item: bool, duration: float = 10.0):
    # Jeśli tracimy przedmiot -> ukrywamy wszystko
    if not has_item:
        llm_container.visible = false
        return

    # Jeśli zdobywamy przedmiot:
    # 1. Pokaż kontener (Ikonę + Tekst)
    llm_container.visible = true
    llm_container.modulate.a = 1.0 
    
    # 2. Pokaż Label (musi być widoczny na start)
    llm_label.visible = true
    llm_label.modulate.a = 1.0
    
    # 3. Zaktualizuj tekst (Wstaw ikony pada/klawiatury)
    update_llm_text_display()
    
    # 4. Uruchom odliczanie do zniknięcia TEKSTU
    if llm_hide_tween:
        llm_hide_tween.kill()
    
    llm_hide_tween = create_tween()
    
    # Czekaj X sekund (tekst widoczny)
    llm_hide_tween.tween_interval(duration)
    
    # Płynnie schowaj TYLKO tekst
    llm_hide_tween.tween_property(llm_label, "modulate:a", 0.0, 1.0)

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
    
    # Fallback: Jeśli nie ma ikony klawiatury, pokaż pada
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

# --- BRAKUJĄCE FUNKCJE (Naprawiają błędy z Twojego screena) ---

func update_ects(new_ects):
    ects_label.text = str(new_ects) + "/30"

func update_motivation(current_val, max_val):
    if motivation_bar:
        motivation_bar.max_value = max_val
        motivation_bar.value = current_val

# (Funkcja update_golden_drink została usunięta, bo nie masz już tego obiektu)
