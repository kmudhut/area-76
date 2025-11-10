extends Node

const SETTINGS_PATH := "user://settings.json"

var user_settings := {
	"general": {
		"difficulty_level": 1,
	},
	"graphics": {
		"screen_mode": "window",
		"resolution": "1920x1080",
	},
	"audio": {
		"main_volume": 0.5,
		"interface_volume": 0.5,
		"sfx_volume": 0.5,
		"music_volume": 0.5
	}
}

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user_settings, "\t"))
		file.close()
		print("Settings saved to", SETTINGS_PATH)
	else:
		push_error("Could not save settings!")

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var result = JSON.parse_string(content)
			if typeof(result) == TYPE_DICTIONARY:
				user_settings = result
				print("Settings loaded from file.")
			else:
				print("Settings file is invalid JSON, using defaults.")
	else:
		print("No settings file found, using defaults.")
		save_settings()


func get_setting(category: String, key: String):
	if user_settings.has(category) and user_settings[category].has(key):
		return user_settings[category][key]
	return null


func set_setting(category: String, key: String, value) -> void:
	if user_settings.has(category) and user_settings[category].has(key):
		user_settings[category][key] = value
		save_settings()
	else:
		push_warning("Tried to set unknown setting: %s/%s" % [category, key])
