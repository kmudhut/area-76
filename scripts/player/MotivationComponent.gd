extends Node
class_name MotivationComponent

signal motivation_depleted() # Śmierć
signal damage_taken(amount)
signal defense_boost_active(is_active)

@export var max_motivation: float = 100.0
var current_motivation: float = 100.0

var damage_reduction_active: bool = false

func _ready():
	current_motivation = max_motivation
	update_gamestate()

func take_damage(amount: float):
	var difficulty_mult = 1.0
	if has_node("/root/GameState"):
		difficulty_mult = get_node("/root/GameState").get_damage_multiplier()
	
	var final_damage = amount * difficulty_mult
	
	if damage_reduction_active:
		final_damage *= 0.5
	
	current_motivation -= final_damage
	current_motivation = clamp(current_motivation, 0, max_motivation)
	
	emit_signal("damage_taken", final_damage)
	update_gamestate() 
	
	if current_motivation <= 0:
		emit_signal("motivation_depleted")

func heal_percent(percent: float):
	var heal_amount = max_motivation * (percent / 100.0)
	current_motivation += heal_amount
	current_motivation = clamp(current_motivation, 0, max_motivation)
	update_gamestate()

func activate_defense_boost(duration: float):
	damage_reduction_active = true
	emit_signal("defense_boost_active", true)
	await get_tree().create_timer(duration).timeout
	damage_reduction_active = false
	emit_signal("defense_boost_active", false)

func update_gamestate():
	if has_node("/root/GameState"):
		get_node("/root/GameState").update_health_ui(current_motivation, max_motivation)
