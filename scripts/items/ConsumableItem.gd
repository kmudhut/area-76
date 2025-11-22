extends Area2D

enum ItemType { 
	ENERGY_DRINK, # +20% HP, +25% Speed
	GOLDEN_DRINK  # +50% HP, -50% Dmg taken
}

@export var type: ItemType = ItemType.ENERGY_DRINK
@onready var animated_sprite = get_node_or_null("AnimatedSprite2D")
@onready var detection_zone = get_node_or_null("DetectionZone")

func _ready():
	body_entered.connect(_on_body_entered)
	
	if type == ItemType.GOLDEN_DRINK:
		if animated_sprite:
			animated_sprite.stop()
			animated_sprite.frame = 0 
		
		if detection_zone:
			detection_zone.body_entered.connect(_on_detection_enter)
			detection_zone.body_exited.connect(_on_detection_exit)

func _on_body_entered(body):
	if body.is_in_group("player"):
		play_pickup_sound()
		apply_effect(body)
		queue_free()

func _on_detection_enter(body):
	if body.is_in_group("player") and animated_sprite:
		animated_sprite.play()

func _on_detection_exit(body):
	if body.is_in_group("player") and animated_sprite:
		animated_sprite.stop()
		animated_sprite.frame = 0

func play_pickup_sound():
	match type:
		ItemType.ENERGY_DRINK:
			AudioManager.play_sfx("sfx/gulp") 
		ItemType.GOLDEN_DRINK:
			AudioManager.play_sfx("sfx/rare_collect")

func apply_effect(player):
	var gs = get_node_or_null("/root/GameState")
	var stats = player.get_node_or_null("MotivationComponent")

	match type:
		ItemType.ENERGY_DRINK:
			if stats: stats.heal_percent(20.0)
			if player.has_method("apply_speed_boost"):
				player.apply_speed_boost(5.0, 1.3)
				
		ItemType.GOLDEN_DRINK:
			if gs: gs.add_golden_drink()
			print("Podniesiono Złoty Napój!")
