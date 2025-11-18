extends CharacterBody2D

func _process(float) -> void:
	pass
	
func _ready() ->void:
	AudioManager.play_sfx("sfx/drone_sound")
	
