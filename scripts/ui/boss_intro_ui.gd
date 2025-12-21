extends CanvasLayer

# --- KONFIGURACJA ---
@export_group("Treść Komunikatu")
@export var alert_title: String = "PRZEKROCZENIE LIMITU MIEJSC"
@export_multiline var alert_description: String = "Brak wolnych miejsc w grupie 'Zaliczenie na 3.0'.\nZostałeś przydzielony do grupy 'Walka o Przetrwanie'."
@export var button_text: String = "akceptuj los"

# --- REFERENCJE ---
@onready var header_label = $WindowPanel/HeaderLabel
@onready var description_label = $WindowPanel/DescriptionLabel
@onready var button_inner_label = $WindowPanel/StartButton/Label 
@onready var start_button = $WindowPanel/StartButton
@onready var window_panel = $WindowPanel

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	# --- NOWE: UKRYWANIE HUD-A ---
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = false
	# -----------------------------
	
	# Przypisanie tekstów
	if header_label: header_label.text = alert_title
	if description_label: description_label.text = alert_description
	if button_inner_label: button_inner_label.text = button_text
	
	# Sygnał przycisku
	if start_button:
		if not start_button.pressed.is_connected(_on_start_button_pressed):
			start_button.pressed.connect(_on_start_button_pressed)
	
	# Animacja
	window_panel.pivot_offset = window_panel.size / 2
	window_panel.scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(window_panel, "scale", Vector2(1, 1), 0.5)

func _on_start_button_pressed():
	get_tree().paused = false
	
	# --- NOWE: POKAZYWANIE HUD-A ---
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = true
	# -------------------------------
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(window_panel, "scale", Vector2(0, 0), 0.2)
	tween.tween_callback(queue_free)
