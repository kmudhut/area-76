extends Control

@onready var scene_manager := get_node("/root/Main/SceneManager")

func _ready():
	$AnimationPlayer.play("RESET")

# ===========================================================
# Pauza
# ===========================================================

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	resume_all_audio()

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	pause_all_audio()

func testEsc():
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused:
		resume()

var paused_audio_players: Array[AudioStreamPlayer] = []

func pause_all_audio():
	paused_audio_players.clear()
	var players = get_tree().get_nodes_in_group("music")
	for p in players:
		if p.playing:
			p.stream_paused = true
			paused_audio_players.append(p)

func resume_all_audio():
	for p in paused_audio_players:
		if is_instance_valid(p):
			p.stream_paused = false
	paused_audio_players.clear()

# ===========================================================
# Przyciski
# ===========================================================

func _on_btn_continue_pressed():
	resume()

func _on_btn_reset_pressed():
	resume()
	GameState.ects = 0
	scene_manager.goto_lvl("Level_01.tscn")

func _on_btn_settings_pressed():
	$SettingsPauseMenu.visible = true

func _on_btn_exit_pressed():
	#GameState.save()				##### zostawić aż do ptk 37,38 backlogu
	scene_manager.goto_menu()

func _process(_delta):
	testEsc()
