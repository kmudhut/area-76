extends Node2D

@onready var boss = $Boss1
@onready var end_screen = $EndScreen
@onready var boss_intro = $BossIntroUI

func _ready():
	# 1. Na start ukrywamy ekran końcowy
	if end_screen:
		end_screen.visible = false
	
	# 2. Czekamy aż boss zniknie (umrze)
	if boss:
		boss.tree_exited.connect(_on_boss_died)
	else:
		print("UWAGA: Nie znaleziono węzła Boss1!")

func _on_boss_died():
	print("Boss pokonany! Wyświetlam podsumowanie.")
	
	var final_ects = GameState.ects
	var max_ects = 30
	
	var next_level_path = ""
	
	# Wywołanie ekranu
	if end_screen:
		end_screen.setup_screen(final_ects, max_ects, next_level_path, "I")
		end_screen.visible = true
