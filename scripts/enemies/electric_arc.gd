extends AnimatedSprite2D
@onready var attack_area = $SpecialAttackArea
var player

var attack_cooldown = 2.0
var current_cooldown = 0.0
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta: float) -> void:
	current_cooldown -= delta
	if attack_area.overlaps_body(player) and current_cooldown <= 0.0 and self.visible:
		player.take_damage(20)
		current_cooldown = attack_cooldown
