extends Node

# Definiujemy sygnały, których nasłuchuje HUD
signal lives_changed(new_lives)
signal energy_changed(new_energy)
signal ects_changed(new_ects)

# Nasze globalne zmienne
var lives = 3
var energy = 0
var ects = 0

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
