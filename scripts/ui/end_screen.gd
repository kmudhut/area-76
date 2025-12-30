extends CanvasLayer

# --- ŚCIEŻKI DO WĘZŁÓW ---
@onready var title_label = $Control/Panel/VBoxContainer/TitleLabel
@onready var grade_label = $Control/Panel/GradeLabel 
@onready var ects_label = $Control/Panel/VBoxContainer/StatsContainer/ECTSLabel
@onready var time_label = $Control/Panel/VBoxContainer/StatsContainer/TimeLabel
@onready var comment_label = $Control/Panel/VBoxContainer/CommentLabel
@onready var next_level_btn = $Control/Panel/VBoxContainer/ButtonsContainer/NextLevelButton

var next_level_scene_path: String = ""

func _ready():
	if time_label:
		time_label.visible = false # wprowadzony w wersji drugiej skryptu 'end_screen.gd'
	grade_label.visible = false

func setup_screen(ects_collected: int, max_ects: int, next_level: String, roman_number: String = "I"):
	get_tree().paused = true
	next_level_scene_path = next_level
	
	# --- 1. USTAWIENIE TEKSTÓW ---
	title_label.text = "%s SEMESTR UKOŃCZONY !" % roman_number
	ects_label.text = "Punkty ECTS: %d / %d" % [ects_collected, max_ects]
	
	# --- 2. OBLICZENIE OCENY ---
	var grade = calculate_grade(ects_collected, max_ects)
	grade_label.text = "%.1f" % grade
	comment_label.text = get_comment_for_grade(grade)
	
	# --- 3. PRZYGOTOWANIE "PIECZĄTKI" (Kolor i Animacja) ---
	var stamp_color = get_color_for_grade(grade)
	grade_label.modulate = stamp_color 
	
	# Uruchamiamy animację stempla
	animate_stamp_effect()

	# --- 4. OBSŁUGA PRZYCISKU (Ukrywanie jeśli koniec gry) ---
	if next_level_scene_path == "":
		next_level_btn.visible = false
	else:
		next_level_btn.visible = true
		
	# Dźwięk (opcjonalny)
	# AudioManager.play_sfx("win_jingle") 

# --- FUNKCJA ANIMACJI PIECZĄTKI ---
func animate_stamp_effect():
	# 1. Przygotowanie: Ustawiamy punkt obrotu/skali na środek labela
	grade_label.pivot_offset = grade_label.size / 2
	
	# Losowy kąt dla realizmu
	grade_label.rotation_degrees = randf_range(-12.0, 12.0)
	
	# Stan początkowy: Ogromna i przezroczysta
	grade_label.scale = Vector2(5.0, 5.0)
	var final_color = grade_label.modulate
	grade_label.modulate.a = 0.0 
	grade_label.visible = true 
	
	# 2. Tworzymy Tween (animację)
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

# Nowa funkcja dobierająca kolor
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
	return "Sesja przetrwana."

# --- OBSŁUGA PRZYCISKÓW (bez zmian) ---
func _on_next_level_button_pressed():
	get_tree().paused = false
	if get_node_or_null("/root/SceneManager"):
		SceneManager.goto_scene(next_level_scene_path)

func _on_retry_button_pressed():
	get_tree().paused = false
	if get_node_or_null("/root/SceneManager"):
		SceneManager.goto_lvl("Level_01")

func _on_menu_button_pressed():
	get_tree().paused = false
	if get_node_or_null("/root/SceneManager"):
		SceneManager.goto_menu()
