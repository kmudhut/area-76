extends CanvasLayer

# --- KONFIGURACJA W INSPEKTORZE ---
@export_group("Konfiguracja Bossa")
@export var boss_node: CharacterBody2D  # Przeciągnij tu Bossa ze sceny
@export var boss_title_texture: Texture2D # Tu wrzuć obrazek z napisem

# --- REFERENCJE DO WĘZŁÓW ---
@onready var title_art = $BossTitleArt
@onready var health_container = $HealthContainer
@onready var progress_bar = $HealthContainer/ProgressBar
@onready var hp_number_label = $HealthContainer/ProgressBar/BarLabel

func _ready():
	
	if boss_node:
		_setup_hud()
		visible = true
	else:
		print("BossHUD: Nie przypisano węzła Bossa w Inspektorze!")
		set_process(false)

func _setup_hud():
	# 1. Ustawienie grafiki tytułowej
	if boss_title_texture:
		title_art.texture = boss_title_texture
	else:
		title_art.visible = false # Ukryj jeśli brak obrazka
		
	# 2. Ustawienie paska
	progress_bar.max_value = boss_node.max_health_points
	progress_bar.value = boss_node.max_health_points
	_update_label_text(boss_node.max_health_points)
	
	# 3. Podłączenie sygnałów
	if boss_node.has_signal("health_changed"):
		boss_node.health_changed.connect(_on_health_changed)

# --- AKTUALIZACJA DANYCH ---

func _on_health_changed(current_hp, _max_hp_signal):
	progress_bar.value = current_hp
	_update_label_text(current_hp)
	if current_hp <= 0:
		visible = false

func _update_label_text(current_val):
	if hp_number_label:
		var curr_txt = str(int(current_val))
		var max_txt = str(int(boss_node.max_health_points))
		hp_number_label.text = "BOSS HP: " + curr_txt + "/" + max_txt
