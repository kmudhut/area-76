extends Node

const SAVE_FILE_TEMPLATE = "user://save_slot_%d.json"
const BOSS_UNLOCK_THRESHOLD = 12

# Konfiguracja liczby checkpointów dla poziomów (do obliczania postępu %)
const LEVEL_TOTAL_CHECKPOINTS = {
	"level_01": 6,
	"level_02": 8,
	"level_03": 12
}

# --- SYGNAŁY ---
signal motivation_changed(current_val, max_val)
signal ects_changed(new_ects)
signal golden_drink_changed(has_drink)
signal llm_charges_changed(count)
signal boss_unlocked()
signal game_over()
signal birets_changed(count)

# --- ZMIENNE STANU GRY ---
var current_slot_index: int = 1

var motivation: float = 100.0
var max_motivation: float = 100.0
var ects: int = 0
var golden_drinks_count: int = 0
var llm_charges: int = 0
var is_usos_active: bool = false
var birets: int = 0
var max_birets: int = 4

# --- ZMIENNE SYSTEMU ZAPISU ---
var current_level_name: String = "level_01"
var last_checkpoint_position: Vector2 = Vector2.ZERO
var is_boss_accessible: bool = false
var collected_items: Array = []
var visited_checkpoints: Array = []

enum Difficulty { EASY, NORMAL, HARD }
var current_difficulty: Difficulty = Difficulty.NORMAL

# --- SETTERY ---
func set_motivation(current, maximum):
	motivation = current
	max_motivation = maximum
	motivation_changed.emit(motivation, max_motivation)
	if motivation <= 0: emit_signal("game_over")

func update_health_ui(current, maximum):
	set_motivation(current, maximum)

func set_ects(new_value):
	ects = new_value
	ects_changed.emit(ects)
	if ects >= BOSS_UNLOCK_THRESHOLD and not is_boss_accessible:
		is_boss_accessible = true
		emit_signal("boss_unlocked")
		
func get_ects():
	return ects
		
func set_golden_drink_count(new_value):
	golden_drinks_count = new_value
	golden_drink_changed.emit(golden_drinks_count > 0)

func set_llm_charges(new_value):
	llm_charges = new_value
	llm_charges_changed.emit(llm_charges)

func set_birets(value: int):
	birets = clamp(value, 0, max_birets)
	emit_signal("birets_changed", birets)

# --- FUNKCJE POMOCNICZE (GAMEPLAY) ---
func add_ects(amount): set_ects(ects + amount)
func add_golden_drink(): set_golden_drink_count(golden_drinks_count + 1)
func add_llm_charge(): set_llm_charges(llm_charges + 1)
func add_birets(amount: int): set_birets(birets + amount)

func use_golden_drink() -> bool:
	if golden_drinks_count > 0:
		set_golden_drink_count(golden_drinks_count - 1)
		return true
	return false

func use_llm_charge() -> bool:
	if llm_charges > 0:
		set_llm_charges(llm_charges - 1)
		return true
	return false

func use_biret() -> bool:
	if birets > 0:
		set_birets(birets - 1)
		return true
	return false

func get_damage_multiplier() -> float:
	match current_difficulty:
		Difficulty.EASY: return 0.75
		Difficulty.NORMAL: return 1.0
		Difficulty.HARD: return 1.5
	return 1.0

# --- OBSŁUGA POZIOMU I ITEMS ---
func activate_checkpoint(position: Vector2, level_path: String, checkpoint_id: String):
	last_checkpoint_position = position
	current_level_name = level_path
	
	if not checkpoint_id in visited_checkpoints:
		visited_checkpoints.append(checkpoint_id)
		
	save_game()

func is_item_collected(item_id: String) -> bool:
	return item_id in collected_items

func register_collected_item(item_id: String):
	if not item_id in collected_items:
		collected_items.append(item_id)

# --- SYSTEM ZAPISU (SLOTY) ---
func get_save_path(slot_index: int) -> String:
	return SAVE_FILE_TEMPLATE % slot_index

func save_game():
	var data = {
		"motivation": motivation,
		"max_motivation": max_motivation,
		"ects": ects,
		"golden_drinks": golden_drinks_count,
		"llm_charges": llm_charges,
		"birets": birets,
		"current_level": current_level_name,
		"checkpoint_x": last_checkpoint_position.x,
		"checkpoint_y": last_checkpoint_position.y,
		"difficulty": current_difficulty,
		"boss_unlocked": is_boss_accessible,
		"collected_items": collected_items,
		"visited_checkpoints": visited_checkpoints
	}
	
	var file_path = get_save_path(current_slot_index)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game(slot_index: int) -> bool:
	var file_path = get_save_path(slot_index)
	if not FileAccess.file_exists(file_path): 
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	
	if parse_result == OK:
		var data = json.data
		current_slot_index = slot_index
		
		motivation = data.get("motivation", 100.0)
		max_motivation = data.get("max_motivation", 100.0)
		ects = data.get("ects", 0)
		golden_drinks_count = data.get("golden_drinks", 0)
		llm_charges = data.get("llm_charges", 0)
		birets = data.get("birets", 0)
		current_level_name = data.get("current_level", "level_01")
		current_difficulty = data.get("difficulty", Difficulty.NORMAL)
		is_boss_accessible = data.get("boss_unlocked", false)
		last_checkpoint_position = Vector2(data.get("checkpoint_x", 0), data.get("checkpoint_y", 0))
		collected_items = data.get("collected_items", [])
		visited_checkpoints = data.get("visited_checkpoints", [])
		
		set_motivation(motivation, max_motivation)
		set_ects(ects)
		set_golden_drink_count(golden_drinks_count)
		set_llm_charges(llm_charges)
		return true
	return false

func get_slot_preview_data(slot_index: int):
	var file_path = get_save_path(slot_index)
	if not FileAccess.file_exists(file_path):
		return null
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	
	if parse_result == OK:
		var data = json.data
		var lvl_name = data.get("current_level", "level_01")
		var visited_list = data.get("visited_checkpoints", [])
		var visited_count = visited_list.size()
		
		var total_checkpoints = LEVEL_TOTAL_CHECKPOINTS.get(lvl_name, 5)
		var progress_percent = 0
		
		var effective_visited = max(0, visited_count - 1)
		var effective_total = max(1, total_checkpoints - 1)
		
		if effective_total > 0:
			progress_percent = int((float(effective_visited) / float(effective_total)) * 100)
			progress_percent = clampi(progress_percent, 0, 100)
			
		return {
			"exists": true,
			"ects": data.get("ects", 0),
			"progress": progress_percent,
			"level_name": lvl_name
		}
	return null

func reset_new_game(slot_index: int):
	current_slot_index = slot_index
	motivation = 100.0
	max_motivation = 100.0
	ects = 0
	golden_drinks_count = 0
	llm_charges = 0
	birets = 0
	collected_items.clear()
	visited_checkpoints.clear()
	current_level_name = "level_01"
	last_checkpoint_position = Vector2.ZERO
	is_boss_accessible = false
	is_usos_active = false
	set_motivation(motivation, max_motivation)
	set_ects(ects)
	save_game()

func restart_level_data():
	print("--- RESTART POZIOMU (SLOT: ", current_slot_index, ") ---")
	last_checkpoint_position = Vector2.ZERO
	ects = 0
	set_ects(0)
	golden_drinks_count = 0
	set_golden_drink_count(0)
	birets = 0
	set_birets(0)
	motivation = max_motivation
	set_motivation(motivation, max_motivation)
	is_boss_accessible = false
	is_usos_active = false
	collected_items.clear()
	visited_checkpoints.clear()
	save_game()
	print("Zresetowano dane dla slotu ", current_slot_index)
