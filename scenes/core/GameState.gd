extends Node

const SAVE_FILE = "user://savegame.json"
const BOSS_UNLOCK_THRESHOLD = 12 

# --- SYGNAŁY ---
signal motivation_changed(current_val, max_val)
signal ects_changed(new_ects)
signal golden_drink_changed(has_drink) 
signal boss_unlocked() 
signal game_over()

# --- ZMIENNE STANU GRY ---
# USUNIĘTO: var lives
var motivation: float = 100.0
var max_motivation: float = 100.0
var ects: int = 0
var golden_drinks_count: int = 0 

# --- DANE POZIOMU ---
var current_level_name: String = "Level1"
var last_checkpoint_position: Vector2 = Vector2.ZERO
var is_boss_accessible: bool = false

# --- POZIOM TRUDNOŚCI ---
enum Difficulty { EASY, NORMAL, HARD }
var current_difficulty: Difficulty = Difficulty.NORMAL

# --- SETTERY ---

func set_motivation(current, maximum):
	motivation = current
	max_motivation = maximum
	motivation_changed.emit(motivation, max_motivation)
	if motivation <= 0:
		emit_signal("game_over")

func update_health_ui(current, maximum):
	set_motivation(current, maximum)

func set_ects(new_value):
	ects = new_value
	ects_changed.emit(ects)
	
	if ects >= BOSS_UNLOCK_THRESHOLD and not is_boss_accessible:
		is_boss_accessible = true
		emit_signal("boss_unlocked")
		print("ZEBRANO 12 ECTS! DROGA DO BOSSA OTWARTA.")

func set_golden_drink_count(new_value):
	golden_drinks_count = new_value
	golden_drink_changed.emit(golden_drinks_count > 0)

# --- FUNKCJE ROZGRYWKI ---

func add_ects(amount):
	set_ects(ects + amount)

func add_golden_drink():
	set_golden_drink_count(golden_drinks_count + 1)

func use_golden_drink() -> bool:
	if golden_drinks_count > 0:
		set_golden_drink_count(golden_drinks_count - 1)
		return true
	return false

func activate_checkpoint(position: Vector2):
	last_checkpoint_position = position
	save_game() 
	print("Checkpoint aktywowany w: ", position)

func get_damage_multiplier() -> float:
	match current_difficulty:
		Difficulty.EASY:
			return 0.75 
		Difficulty.NORMAL:
			return 1.0
		Difficulty.HARD:
			return 1.5 
	return 1.0

# --- SYSTEM ZAPISU ---

func save_game():
	var data = {
		"motivation": motivation,
		"ects": ects,
		"golden_drinks": golden_drinks_count,
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
		print("Gra zapisana.")
	else:
		push_error("Błąd zapisu gry.")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("Brak pliku zapisu.")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data
		motivation = data.get("motivation", 100.0)
		ects = data.get("ects", 0)
		golden_drinks_count = data.get("golden_drinks", 0)
		current_level_name = data.get("current_level", "Level1")
		current_difficulty = data.get("difficulty", Difficulty.NORMAL)
		is_boss_accessible = data.get("boss_unlocked", false)
		
		var x = data.get("checkpoint_x", 0)
		var y = data.get("checkpoint_y", 0)
		last_checkpoint_position = Vector2(x, y)
		
		# Odświeżamy UI
		set_motivation(motivation, max_motivation)
		set_ects(ects)
		set_golden_drink_count(golden_drinks_count)
		
		print("Gra wczytana pomyślnie.")
	else:
		print("Błąd parsowania pliku zapisu.")
