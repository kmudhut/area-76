extends CenterContainer
@onready var exercise_texture_rect = $Panel/VBoxContainer/MarginContainer4/TextureRect
@onready var user_answer_input = $Panel/VBoxContainer/MarginContainer3/UserAnswer
var player : CharacterBody2D
var answers = {
		"math1.png": "10",
		"math2": ["sword", "shield", "map"],
		"math3": "Castellion",
		"math4": 67
	}

func _ready() -> void:
	get_parent().get_node("Boss1").process_mode = Node.PROCESS_MODE_DISABLED
	get_parent().get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	$Panel/VBoxContainer/MarginContainer3/UserAnswer.grab_focus()

func _on_button_pressed() -> void:
	var correct_answer = answers[exercise_texture_rect.texture.resource_path.get_file()]
	var user_answer = user_answer_input.text
	if(user_answer != correct_answer):
		player.take_damage(33)
	get_parent().get_node("Boss1").process_mode = Node.PROCESS_MODE_PAUSABLE
	get_parent().get_node("Player").process_mode = Node.PROCESS_MODE_PAUSABLE
	queue_free()
