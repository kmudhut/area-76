extends Area2D

# --- KONFIGURACJA ---
enum ItemType { 
	ENERGY_DRINK, 
	GOLDEN_DRINK, 
	LLM_ITEM, 
	ECTS
}

@export var type: ItemType = ItemType.ENERGY_DRINK
@export var ects_value: int = 1 

@onready var animated_sprite = get_node_or_null("AnimatedSprite2D")
@onready var detection_zone = get_node_or_null("DetectionZone")

# Nowe: Referencje do efektów specjalnych (Aury)
@onready var rainbow_aura = get_node_or_null("RainbowAura") # Dla LLM
@onready var glow_effect = get_node_or_null("GlowEffect")   # Dla Golden Drink

# --- INICJALIZACJA ---
func _ready():
	body_entered.connect(_on_body_entered)
	
	if type == ItemType.GOLDEN_DRINK or type == ItemType.LLM_ITEM:
		if animated_sprite:
			animated_sprite.stop()
			animated_sprite.frame = 0 
		
		if detection_zone:
			detection_zone.body_entered.connect(_on_detection_enter)
			detection_zone.body_exited.connect(_on_detection_exit)
			
		set_aura_active(false)

# --- OBSŁUGA ZDARZEŃ (KOLIZJE) ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		play_pickup_sound()
		apply_effect(body)
		queue_free()

func _on_detection_enter(body):
	if body.is_in_group("player"):
		if animated_sprite: animated_sprite.play()
		set_aura_active(true)

func _on_detection_exit(body):
	if body.is_in_group("player"):
		if animated_sprite: 
			animated_sprite.stop()
			animated_sprite.frame = 0
		set_aura_active(false)

# --- STEROWANIE AURAMI (SHADERAMI) ---
func set_aura_active(is_active: bool):
	if type == ItemType.LLM_ITEM and rainbow_aura:
		var mat = rainbow_aura.material as ShaderMaterial
		if mat: mat.set_shader_parameter("active", is_active)
		
	elif type == ItemType.GOLDEN_DRINK and glow_effect:
		pass

# --- DŹWIĘKI ---
func play_pickup_sound():
	match type:
		ItemType.ENERGY_DRINK: AudioManager.play_sfx("sfx/energy_drink") 
		ItemType.GOLDEN_DRINK: AudioManager.play_sfx("sfx/golden_drink_collect") 
		ItemType.LLM_ITEM: AudioManager.play_sfx("sfx/powerup_collect") 
		ItemType.ECTS: AudioManager.play_sfx("sfx/ects_collected")

# --- EFEKTY PRZEDMIOTÓW ---
func apply_effect(player):
	var gs = get_node_or_null("/root/GameState")
	var stats = player.get_node_or_null("MotivationComponent")

	match type:
		ItemType.ENERGY_DRINK:
			if stats: stats.heal_percent(20.0)
			if player.has_method("apply_speed_boost"):
				player.apply_speed_boost(5.0, 1.25)
				
		ItemType.GOLDEN_DRINK:
			if stats: stats.heal_percent(50.0)
			if player.has_method("apply_speed_boost"):
				player.apply_speed_boost(5.0, 1.25)
			if player.has_method("play_golden_flash_effect"):
				player.play_golden_flash_effect()
			print("Wypito Złoty Napój!")
			
		ItemType.LLM_ITEM:
			if gs: gs.add_llm_charge()
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_llm_powerup"):
				hud.show_llm_powerup(true)
			print("Podniesiono Wiedzę LLM!")
		
		ItemType.ECTS:
			if gs: gs.add_ects(ects_value)
