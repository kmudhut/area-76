extends CharacterBody2D

@export var speed := 250.0
@export var amplitude := 50.0
@export var frequency := 1.0

var player: Node2D
var time := 0.0

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta):
	if not player:
		return
	time += delta
	
	var hover_offset = Vector2(
		sin(time * (frequency*0.9)) * amplitude,
		cos(time * (frequency*1.1)) * amplitude
		)
	var target_position = Vector2(player.global_position.x, player.global_position.y - 400) + hover_offset
	global_position = global_position.move_toward(target_position, speed * delta)
