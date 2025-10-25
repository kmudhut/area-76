extends Node

# Sygnały, które "krzykną", gdy coś się zmieni
signal lives_changed(new_lives)
signal energy_changed(new_energy)
signal coins_changed(new_coins)

# Zmienne przechowujące dane
var lives: int = 5:
	set(value):
		lives = value
		lives_changed.emit(lives) # "Krzyczymy", że życia się zmieniły!

var energy: int = 5:
	set(value):
		energy = value
		energy_changed.emit(energy) # Poprawiony sygnał

var coins: int = 0: # Ustawiamy start na 0, jak prosiłeś
	set(value):
		coins = value
		coins_changed.emit(coins) # Poprawiony sygnał
