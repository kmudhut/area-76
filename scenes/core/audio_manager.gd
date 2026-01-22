extends Node

const AUDIO_PATH := "res://assets/audio/"

var music_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var sfx_players := [] 

var sounds := {}

func _ready():
	music_player = AudioStreamPlayer.new()
	ui_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(ui_player)
	for i in range(10):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	preload_all_sounds()
	apply_sound_settings(UserPreferences.get_settings_by_category("audio"))
	

func apply_sound_settings(settings: Dictionary) -> bool:
	var main_volume = settings["main_volume"]
	var sfx_volume = settings["sfx_volume"]
	var ui_volume = settings["interface_volume"]
	var music_volume = settings["music_volume"]
	music_player.volume_db = linear_to_db(main_volume * music_volume)
	ui_player.volume_db = linear_to_db(main_volume * ui_volume)
	for sfx_player in sfx_players:
		sfx_player.volume_db = linear_to_db(main_volume * sfx_volume)
	return 1
	
func preload_all_sounds(base_path := AUDIO_PATH):
	var dir = DirAccess.open(base_path)
	if not dir:
		push_error("Could not open audio directory: " + base_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				preload_all_sounds(base_path + file_name + "/")
		else:
			var file_to_check = file_name
			if file_name.ends_with(".import"):
				file_to_check = file_name.replace(".import", "")


			if file_to_check.ends_with(".wav") or file_to_check.ends_with(".ogg") or file_to_check.ends_with(".mp3"):
				
				var full_path = base_path + file_to_check
				
				var relative_key = full_path.replace(AUDIO_PATH, "").get_basename()
				
				if not sounds.has(relative_key):
					var stream = load(full_path) # TU JEST TWÓJ LOAD
					print("FULL PATH: ", full_path)
					
					if stream:
						sounds[relative_key] = stream
						print("Loaded sound:", relative_key)
						
		file_name = dir.get_next()
	dir.list_dir_end()

func play_music(sound_name: String, _loop := true):
	if not sounds.has(sound_name):
		push_warning("No music found: " + sound_name)
		return
	music_player.stream = sounds[sound_name]
	#music_player.loop = loop
	music_player.play()

func stop_music():
	music_player.stop()

func play_sfx(name: String) -> AudioStreamPlayer:
	if not sounds.has(name):
		push_warning("No sfx found: " + name)
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = sounds[name]
			player.play()
			return player
	sfx_players[0].stream = sounds[name]
	sfx_players[0].play()
	return sfx_players[0]

func play_ui_sound(name: String):
	if not sounds.has(name):
		push_warning("No UI sound found: " + name)
		return
	ui_player.stream = sounds[name]
	ui_player.play()
