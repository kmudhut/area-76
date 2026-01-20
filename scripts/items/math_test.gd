extends CenterContainer
@onready var exercise_texture_rect = $Panel/VBoxContainer/MarginContainer4/TextureRect
@onready var user_answer_input = $Panel/VBoxContainer/MarginContainer3/UserAnswer
@onready var time_remaining = $Panel/VBoxContainer/TitleMargin2/VBoxContainer/TimeRemaining 
@onready var timer = $Timer
var tick_player

var player : CharacterBody2D
var answers = {
		"math1.png": "10",
		"math2.png": "8",
	}

func _ready() -> void:
	get_parent().get_node("Boss1").process_mode = Node.PROCESS_MODE_DISABLED
	get_parent().get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var exercise = load("res://assets/tests/math%s.png" % randi_range(1, 2))
	if exercise:
		exercise_texture_rect.texture = exercise
	else:
		print("Nie znaleziono pliku z teksturą!")
		
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	$Panel/VBoxContainer/MarginContainer3/UserAnswer.grab_focus()
	tick_player = AudioManager.play_sfx("sfx/clock-ticking")

func _process(delta: float) -> void:
	var seconds = int(timer.get_time_left());
	if seconds < 10:
		time_remaining.add_theme_color_override("font_color", Color.RED)
	time_remaining.text = "00:%02d" % seconds
	
func check_answer() -> void:
	var correct_answer = answers[exercise_texture_rect.texture.resource_path.get_file()]
	var user_answer = user_answer_input.text
	if(user_answer != correct_answer):
		player.take_damage(33)
		AudioManager.play_sfx("sfx/otoznie")
	else: AudioManager.play_sfx("sfx/correct")
	get_parent().get_node("Boss1").process_mode = Node.PROCESS_MODE_PAUSABLE
	get_parent().get_node("Player").process_mode = Node.PROCESS_MODE_PAUSABLE
	tick_player.stop();
	queue_free()

func _on_button_pressed() -> void:
	check_answer()

func _on_timer_timeout() -> void:
	check_answer()

func _exit_tree() -> void:
	if tick_player:
		tick_player.stop()
