extends Node
const SAVE_FILE = "user://savegame.json"

# Definiujemy sygnały, których nasłuchuje HUD
signal lives_changed(new_lives)
signal energy_changed(new_energy)
signal ects_changed(new_ects)

# Nasze globalne zmienne
var lives = 3
var energy = 0
var ects = 0
var current_level := "Level1"
var player_position := Vector2.ZERO

# Używamy setterów, aby automatycznie wysyłać sygnał przy zmianie
func set_lives(new_value):
	lives = new_value
	lives_changed.emit(lives)

func set_energy(new_value):
	energy = new_value
	energy_changed.emit(energy)

func set_ects(new_value):
	ects = new_value
	ects_changed.emit(ects)

# Przykładowa funkcja, którą gracz może wywołać
func add_ects(amount):
	set_ects(ects + amount)


func save():
	var data = {
		"lives": lives,
		"ects": ects,
		"energy": energy,
		"current_level": current_level,
		"player_position": player_position
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Zapisano grę.")
	else:
		push_error("Nie mogę zapisać savegame.json")
