extends Control

# Referencje do przycisków
@onready var slot1_btn = $HBoxContainer/Slot1_Btn
@onready var slot2_btn = $HBoxContainer/Slot2_Btn
@onready var slot3_btn = $HBoxContainer/Slot3_Btn

signal closed

var is_loading_mode = true 

func _ready():
	visible = false

# Obsługa ESC
func _input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close_save_window()

func open_save_window(loading_mode: bool):
	is_loading_mode = loading_mode
	visible = true
	update_slot_buttons()
	await get_tree().process_frame
	
	if not slot1_btn.disabled:
		slot1_btn.grab_focus()
	elif not slot2_btn.disabled:
		slot2_btn.grab_focus()
	elif not slot3_btn.disabled:
		slot3_btn.grab_focus()
	else:
		pass

func close_save_window():
	visible = false
	closed.emit()

func update_slot_buttons():
	update_single_button(slot1_btn, 1, "SEMESTR I")
	update_single_button(slot2_btn, 2, "SEMESTR II")
	update_single_button(slot3_btn, 3, "SEMESTR III")

func update_single_button(btn: Button, slot_index: int, title: String):
	var data = GameState.get_slot_preview_data(slot_index)
	
	var container = btn.get_node("VBoxContainer")
	var title_lbl = container.get_node("Title")
	var progress_lbl = container.get_node("Progress")
	var ects_lbl = container.get_node("ECTS")
	
	title_lbl.text = title
	
	# Upewniamy się, że sam przycisk i kontener nie są przyciemnione
	btn.modulate = Color(1, 1, 1, 1)
	container.modulate = Color(1, 1, 1, 1)
	
	# Definiujemy kolory
	var white_color = Color(1, 1, 1, 1)
	var grey_color = Color(0.5, 0.5, 0.5, 1)
	
	if data == null:
		# --- PUSTY SLOT ---
		if is_loading_mode:
			# WCZYTYWANIE -> Pusty jest nieaktywny
			btn.disabled = true
			progress_lbl.text = "BRAK ZAPISU"
			ects_lbl.text = ""
			
			force_label_color(title_lbl, grey_color)
			force_label_color(progress_lbl, grey_color)
			force_label_color(ects_lbl, grey_color)
		else:
			# NOWA GRA -> Pusty jest dostępny
			btn.disabled = false
			progress_lbl.text = "WOLNY SLOT"
			ects_lbl.text = ""
			
			force_label_color(title_lbl, white_color)
			force_label_color(progress_lbl, white_color)
			force_label_color(ects_lbl, white_color)
	else:
		# --- ZAJĘTY SLOT ---
		btn.disabled = false
		progress_lbl.text = "POSTĘP: %d%%" % data.progress
		ects_lbl.text = "ECTS: %d/30" % data.ects
		
		force_label_color(title_lbl, white_color)
		force_label_color(progress_lbl, white_color)
		force_label_color(ects_lbl, white_color)
	
	# Podpinanie sygnałów
	if btn.pressed.is_connected(_on_slot_pressed):
		btn.pressed.disconnect(_on_slot_pressed)
	btn.pressed.connect(_on_slot_pressed.bind(slot_index))

func force_label_color(lbl: Label, color: Color):
	lbl.add_theme_color_override("font_color", color)
	if lbl.label_settings:
		if not lbl.label_settings.resource_local_to_scene:
			lbl.label_settings = lbl.label_settings.duplicate()
			lbl.label_settings.resource_local_to_scene = true
			
		lbl.label_settings.font_color = color

func _on_slot_pressed(slot_index: int):
	if is_loading_mode:
		if GameState.load_game(slot_index):
			print("Wczytano slot: ", slot_index)
			SceneManager.goto_lvl(GameState.current_level_name)
			close_save_window()
	else:
		print("Rozpoczynanie nowej gry na slocie: ", slot_index)
		GameState.reset_new_game(slot_index)
		SceneManager.goto_lvl("Level_01")
		close_save_window()

func _on_dimmer_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		close_save_window()
