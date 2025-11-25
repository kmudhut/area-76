extends Node

const SAVE_FILE = "user://savegame.json"
const BOSS_UNLOCK_THRESHOLD = 12 

# --- SYGNAŁY ---
signal motivation_changed(current_val, max_val)
signal ects_changed(new_ects)
signal golden_drink_changed(has_drink) 
signal llm_charges_changed(count)
signal boss_unlocked() 
signal game_over()

# --- ZMIENNE ---
var motivation: float = 100.0
var max_motivation: float = 100.0
var ects: int = 0
var golden_drinks_count: int = 0 
var llm_charges: int = 0

var current_level_name: String = "Level1"
var last_checkpoint_position: Vector2 = Vector2.ZERO
var is_boss_accessible: bool = false

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

func set_golden_drink_count(new_value):
	golden_drinks_count = new_value
	golden_drink_changed.emit(golden_drinks_count > 0)

# --- NOWE FUNKCJE DLA LLM ---
func set_llm_charges(new_value):
	llm_charges = new_value
	llm_charges_changed.emit(llm_charges)

func add_llm_charge():
	set_llm_charges(llm_charges + 1)

func use_llm_charge() -> bool:
	if llm_charges > 0:
		set_llm_charges(llm_charges - 1)
		return true
	return false

# --- RESZTA FUNKCJI ---
func add_ects(amount): set_ects(ects + amount)
func add_golden_drink(): set_golden_drink_count(golden_drinks_count + 1)

func use_golden_drink() -> bool:
	if golden_drinks_count > 0:
		set_golden_drink_count(golden_drinks_count - 1)
		return true
	return false

func activate_checkpoint(position: Vector2):
	last_checkpoint_position = position
	save_game() 

func get_damage_multiplier() -> float:
	match current_difficulty:
		Difficulty.EASY: return 0.75 
		Difficulty.NORMAL: return 1.0
		Difficulty.HARD: return 1.5 
	return 1.0

# --- SAVE SYSTEM ---
func save_game():
	var data = {
		"motivation": motivation,
		"ects": ects,
		"golden_drinks": golden_drinks_count,
		"llm_charges": llm_charges,
		"current_level": current_level_name,
		"checkpoint_x": last_checkpoint_position.x,
		"checkpoint_y": last_checkpoint_position.y,
		"difficulty": current_difficulty,
		"boss_unlocked": is_boss_accessible
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_FILE): return
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.data
		motivation = data.get("motivation", 100.0)
		ects = data.get("ects", 0)
		golden_drinks_count = data.get("golden_drinks", 0)
		llm_charges = data.get("llm_charges", 0)
		current_level_name = data.get("current_level", "Level1")
		current_difficulty = data.get("difficulty", Difficulty.NORMAL)
		is_boss_accessible = data.get("boss_unlocked", false)
		last_checkpoint_position = Vector2(data.get("checkpoint_x", 0), data.get("checkpoint_y", 0))
		
		set_motivation(motivation, max_motivation)
		set_ects(ects)
		set_golden_drink_count(golden_drinks_count)
		set_llm_charges(llm_charges)
