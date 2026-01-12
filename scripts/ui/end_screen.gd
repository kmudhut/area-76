extends CanvasLayer

# --- ZMIENNE ---
@onready var title_label = $Control/Panel/VBoxContainer/TitleLabel
@onready var grade_label = $Control/Panel/GradeLabel 
@onready var ects_label = $Control/Panel/VBoxContainer/StatsContainer/ECTSLabel
@onready var comment_label = $Control/Panel/VBoxContainer/CommentLabel
@onready var next_level_btn = $Control/Panel/VBoxContainer/ButtonsContainer/NextLevelButton
@onready var menu_btn = $Control/Panel/VBoxContainer/ButtonsContainer/MenuButton

var next_level_scene_path: String = ""

var is_triggered: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_triggered = false # Resetujemy flagę na starcie

# --- OPCJA 1: WYGRANA (Zaliczenie Semestru) ---
func setup_win_screen(ects_collected: int, max_ects: int, next_level: String, roman_number: String = "I"):
	# ZABEZPIECZENIE: Jeśli ekran już jest w trakcie wyświetlania, przerwij
	if is_triggered:
		return
	is_triggered = true
	
	get_tree().paused = true
	next_level_scene_path = next_level
	
	# Teksty
	title_label.text = "%s SEMESTR UKOŃCZONY !" % roman_number
	title_label.modulate = Color(1, 1, 1)
	ects_label.text = "Punkty ECTS: %d / %d" % [ects_collected, max_ects]
	
	# Ocena
	var grade = calculate_grade(ects_collected, max_ects)
	grade_label.text = "%.1f" % grade
	comment_label.text = get_comment_for_grade(grade)
	var stamp_color = get_color_for_grade(grade)
	grade_label.modulate = stamp_color
	animate_stamp_effect()
	
	# Przyciski
	if next_level == "":
		next_level_btn.visible = false
		menu_btn.visible = true
	else:
		next_level_btn.visible = true
		menu_btn.visible = false

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("sfx/victory2")

# --- OPCJA 2: PRZEGRANA (Poprawka / Śmierć) ---
func setup_game_over_screen():
	if is_triggered:
		return
	is_triggered = true
	get_tree().paused = true
	
	# Teksty
	title_label.text = "POPRAWKA !"
	title_label.modulate = Color(0.9, 0.1, 0.1)
	ects_label.text = "Zabrane ECTS: %d" % GameState.ects
	
	# Ocena 2.0
	grade_label.text = "2.0"
	grade_label.modulate = Color(0.8, 0.0, 0.0)
	animate_stamp_effect()
	
	comment_label.text = get_comment_for_grade(2.0)
	
	next_level_btn.visible = false
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("sfx/game-over")

# --- FUNKCJA ANIMACJI PIECZĄTKI ---
func animate_stamp_effect():
	grade_label.pivot_offset = grade_label.size / 2
	
	grade_label.rotation_degrees = randf_range(-12.0, 12.0)
	
	grade_label.scale = Vector2(5.0, 5.0)
	var final_color = grade_label.modulate
	grade_label.modulate.a = 0.0 
	grade_label.visible = true 
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	tween.tween_property(grade_label, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
	tween.tween_property(grade_label, "modulate:a", final_color.a, 0.3)

# --- FUNKCJE POMOCNICZE ---
func calculate_grade(current: int, max_val: int) -> float:
	if max_val == 0: return 2.0
	var percent = float(current) / float(max_val)
	if percent < 0.50: return 3.0
	if percent < 0.70: return 3.5
	if percent < 0.85: return 4.0
	if percent < 0.95: return 4.5
	return 5.0

func get_color_for_grade(grade: float) -> Color:
	if grade <= 3.5:
		return Color("ffab1aff")
	elif grade <= 4.5:
		return Color("1a33b3ff")
	else: # 5.0
		return Color("00af00ff")

func get_comment_for_grade(grade: float) -> String:
	match grade:
		3.0: return "3 razy Z: Zakuć, Zdać, Zapomnieć."
		3.5: return "Bez warunku, jest dobrze."
		4.0: return "Solidna robota. Stypendium blisko."
		4.5: return "Prawie idealnie, zabrakło 1 kolosa."
		5.0: return "Student Roku! Dziekan płakał jak wpisywał."
	return "Widzimy się za rok..."

# --- PRZYCISKI ---
func _on_next_level_button_pressed():
	get_tree().paused = false
	GameState.is_usos_active = false
	SceneManager.goto_lvl(next_level_scene_path)

func _on_retry_button_pressed():
	get_tree().paused = false
	GameState.is_usos_active = false
	if GameState.load_game(GameState.current_slot_index):
		GameState.set_motivation(GameState.max_motivation, GameState.max_motivation)
		var level_to_load = GameState.current_level_name + ".tscn"
		SceneManager.goto_lvl(level_to_load)
	else:
		GameState.reset_new_game(GameState.current_slot_index)
		SceneManager.goto_lvl("Level_01.tscn")

func _on_menu_button_pressed():
	get_tree().paused = false
	GameState.is_usos_active = false
	SceneManager.goto_menu()
