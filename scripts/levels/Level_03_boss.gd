extends Node2D

@onready var boss = $Boss3
@onready var end_screen = $EndScreen
@onready var boss_intro = $BossIntroUI

func _ready():
	if boss_intro:
		boss_intro.visible = true
	if end_screen:
		end_screen.visible = false
	if boss:
		boss.boss_defeated.connect(_on_boss_died)
	
	GameState.game_over.connect(_on_game_over)

func _on_boss_died():
	if not is_inside_tree(): return
	
	GameState.is_usos_active = true # blokowanie ekranu pauzy
	
	print("Boss3 pokonany! Wyświetlam podsumowanie.")
	
	var final_ects = GameState.ects
	var max_ects = 30
	
	var next_level_path = ""
	
	# Wywołanie ekranu
	if end_screen:
		end_screen.setup_win_screen(final_ects, max_ects, next_level_path, "III")
		end_screen.visible = true

func _on_game_over():
	if not is_inside_tree(): return
	
	print("Gracz pokonany przez Bossa3!")
	
	await get_tree().create_timer(2.5).timeout
	GameState.is_usos_active = true # blokowanie ekranu pauzy
	
	if end_screen:
		end_screen.setup_game_over_screen()
		end_screen.visible = true
