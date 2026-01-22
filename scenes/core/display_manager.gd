extends Node

func _ready() -> void:
	apply_graphics_settings(UserPreferences.get_settings_by_category("graphics"))
func center_window(width: int, height: int):
	var screen_size = DisplayServer.screen_get_size(0) # ekran główny
	var x = int((screen_size.x - width) / 2)
	var y = int((screen_size.y - height) / 2)
	DisplayServer.window_set_position(Vector2i(x, y))
	
func apply_graphics_settings(settings: Dictionary) -> bool:
	var width = int(settings["resolution"].split('x')[0]);
	var height = int(settings["resolution"].split('x')[1]);
	
	match settings["screen_mode"]:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"window":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
			DisplayServer.window_set_size(Vector2i(width, height))
			center_window(width, height)
	return 1
