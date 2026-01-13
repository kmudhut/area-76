extends CanvasLayer

var spent_ects_total: int = 0

@onready var background = $Background
@onready var center_container = $CenterContainer
@onready var ects_label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ECTSCounter

func _ready():
	background.hide()
	center_container.hide()

func _process(_delta):
	if Input.is_action_pressed("ects_store"):
		_update_and_show()
	else:
		_hide_store()

func _update_and_show():
	var current_balance = GameState.get_ects() - spent_ects_total
	ects_label.text = "Dostępne ECTS: " + str(current_balance)
	background.show()
	center_container.show()

func _hide_store():
	background.hide()
	center_container.hide()


func _on_energy_drink_pressed() -> void:
	var cost = 4
	if _can_afford(cost):
		spent_ects_total += cost
		GameState.set_motivation(GameState.max_motivation, GameState.max_motivation)
		print("Bought Energy Drink: Motivation Refilled")
		_update_and_show()

func _on_golden_drink_pressed() -> void:
	var cost = 6
	if _can_afford(cost):
		spent_ects_total += cost
		GameState.add_golden_drink()
		print("Bought Golden Drink")
		_update_and_show()

func _on_hat_pressed() -> void:
	var cost = 7
	if _can_afford(cost):
		spent_ects_total += cost
		GameState.add_birets(1)
		print("Bought Hat (Biret)")
		_update_and_show()

func _on_llm_pressed() -> void:
	var cost = 10
	if _can_afford(cost):
		spent_ects_total += cost
		GameState.add_llm_charge()
		print("Bought LLM Charge")
		_update_and_show()

func _can_afford(price: int) -> bool:
	var current_balance = GameState.get_ects() - spent_ects_total
	return current_balance >= price
