extends CanvasLayer

# --- KONFIGURACJA W INSPEKTORZE ---
@export_group("Konfiguracja Bossa")
@export var boss_node: CharacterBody2D  # Przeciągnij tu Bossa ze sceny
@export var boss_title_texture: Texture2D # Tu wrzuć obrazek z napisem
@export var title_scale: Vector2 = Vector2(1.0, 1.0)

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
	if boss_title_texture:
		title_art.texture = boss_title_texture
		title_art.visible = true 
		title_art.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var screen_w = get_viewport().get_visible_rect().size.x
		var tex_w = boss_title_texture.get_width()
		var tex_h = boss_title_texture.get_height()
		title_art.pivot_offset = Vector2(tex_w / 2, tex_h / 2)
		title_art.scale = title_scale
		title_art.position.x = (screen_w / 2) - (tex_w / 2)
		title_art.position.y = -350
	else:
		title_art.visible = false
		
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
