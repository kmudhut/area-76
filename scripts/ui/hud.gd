extends CanvasLayer

@onready var hearts_container = $HeartsContainer
@onready var energy_container = $EnergyContainer
@onready var ects_label = $CoinContainer/CoinLabel

func _ready():
	# Połączenie HUD z globalnym GameState (autoload)
	GameState.lives_changed.connect(update_lives)
	GameState.energy_changed.connect(update_energy)
	GameState.ects_changed.connect(update_ects)

	# Ustawienie wartości początkowych
	update_lives(GameState.lives)
	update_energy(GameState.energy)
	update_ects(GameState.ects)


# --- AKTUALIZACJA ŻYCIA ---
func update_lives(new_lives):
	var hearts = hearts_container.get_children()
	for i in range(hearts.size()):
		hearts[i].visible = (i < new_lives)


# --- AKTUALIZACJA ENERGII ---
func update_energy(new_energy):
	var energy_drinks = energy_container.get_children()
	for i in range(energy_drinks.size()):
		energy_drinks[i].visible = (i < new_energy)


# --- AKTUALIZACJA PUNKTÓW ECTS ---
func update_ects(new_ects):
	ects_label.text = str(new_ects) + "/30"
