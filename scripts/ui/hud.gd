extends CanvasLayer

@onready var motivation_bar = $MotivationContainer/MotivationBar
@onready var ects_label = $CoinContainer/CoinLabel
@onready var golden_drink_icon = $GoldenDrinkContainer/GoldenDrinkIcon 

func _ready():
	if not GameState.ects_changed.is_connected(update_ects):
		GameState.ects_changed.connect(update_ects)
	
	if not GameState.motivation_changed.is_connected(update_motivation):
		GameState.motivation_changed.connect(update_motivation)
	
	if not GameState.golden_drink_changed.is_connected(update_golden_drink_icon):
		GameState.golden_drink_changed.connect(update_golden_drink_icon)

	update_ects(GameState.ects)
	update_motivation(GameState.motivation, GameState.max_motivation)
	
	update_golden_drink_icon(GameState.golden_drinks_count > 0)


func update_ects(new_ects):
	ects_label.text = str(new_ects) + "/30"

func update_motivation(current_val, max_val):
	if motivation_bar:
		motivation_bar.max_value = max_val
		motivation_bar.value = current_val

# Funkcja sterująca widocznością
func update_golden_drink_icon(has_drink):
	if golden_drink_icon:
		golden_drink_icon.visible = has_drink
	else:
		print_debug("BŁĄD: Brak węzła GoldenDrinkIcon w scenie HUD!")
