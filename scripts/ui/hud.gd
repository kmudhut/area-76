extends CanvasLayer

@onready var hearts_container = $HeartsContainer
@onready var energy_container = $EnergyContainer
@onready var ects_label = $EctsContainer/EctsLabel # Renamed from CoinLabel

var game_state = null # We will store the reference here

func _ready():
	# Wait for the Main scene to be ready and find GameState
	await get_tree().root.ready 
	game_state = get_node("/root/Main/GameState")
	
	if game_state:
		# Connect to signals from our GameState
		game_state.lives_changed.connect(update_lives)
		game_state.energy_changed.connect(update_energy)
		game_state.ects_changed.connect(update_ects)
		
		# Set initial values
		update_lives(game_state.lives)
		update_energy(game_state.energy)
		update_ects(game_state.ects)
	else:
		print("CRITICAL ERROR: HUD.gd could not find /root/Main/GameState")

func update_lives(new_lives):
	var hearts = hearts_container.get_children()
	for i in range(hearts.size()):
		hearts[i].visible = (i < new_lives) 

func update_energy(new_energy):
	var energy_drinks = energy_container.get_children()
	for i in range(energy_drinks.size()):
		energy_drinks[i].visible = (i < new_energy)

func update_ects(new_ects):
	ects_label.text = "x" + str(new_ects)
