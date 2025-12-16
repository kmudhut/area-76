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

# Referencje do efektów specjalnych (Aury)
@onready var rainbow_aura = get_node_or_null("RainbowAura") 
@onready var glow_effect = get_node_or_null("GlowEffect")   

# --- ZMIENNA DO SYSTEMU ZAPISU ---
var unique_id: String = "" # <--- ZMIANA: Zmienna na unikalne ID

# --- INICJALIZACJA ---
func _ready():
	# <--- ZMIANA: GENEROWANIE UNIKALNEGO ID ---
	# Tworzymy ID na podstawie nazwy sceny i pozycji. To musi być unikalne dla każdego obiektu!
	unique_id = get_tree().current_scene.name + "_" + str(global_position)
	
	# <--- ZMIANA: SPRAWDZANIE CZY JUŻ ZEBRANO ---
	# Pytamy GameState, czy ten przedmiot jest na liście "zebranych"
	if GameState.is_item_collected(unique_id):
		queue_free() # Jeśli tak, usuwamy go natychmiast
		return       # I przerywamy dalsze ładowanie
	
	# --- Standardowa reszta funkcji _ready ---
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
		# <--- ZMIANA: REJESTRACJA ZEBRANIA ---
		# Zanim usuniemy obiekt, mówimy GameState: "Zapamiętaj, że ten ID zniknął"
		GameState.register_collected_item(unique_id)
		
		play_pickup_sound()
		apply_effect(body)
		
		# Ukrywamy wizualnie, żeby gracz nie widział momentu usunięcia
		visible = false 
		call_deferred("queue_free") # Bezpieczne usunięcie

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
	# Zabezpieczenie, gdyby AudioManager nie istniał (dla testów)
	if not AudioManager: return 
	
	match type:
		ItemType.ENERGY_DRINK: AudioManager.play_sfx("sfx/energy_drink") 
		ItemType.GOLDEN_DRINK: AudioManager.play_sfx("sfx/golden_drink_collect") 
		ItemType.LLM_ITEM: AudioManager.play_sfx("sfx/powerup_collect") 
		ItemType.ECTS: AudioManager.play_sfx("sfx/ects_collected")

# --- EFEKTY PRZEDMIOTÓW ---
func apply_effect(player):
	# Używamy bezpośrednio GameState (bo jest Autoloadem), ale get_node też jest OK
	var gs = GameState 
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
			
			# <--- ZMIANA: Dodajemy też napój do ekwipunku w GameState
			if gs: gs.add_golden_drink() 
			print("Wypito Złoty Napój!")
			
		ItemType.LLM_ITEM:
			if gs: gs.add_llm_charge()
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_llm_powerup"):
				hud.show_llm_powerup(true)
			print("Podniesiono Wiedzę LLM!")
		
		ItemType.ECTS:
			if gs: gs.add_ects(ects_value)
