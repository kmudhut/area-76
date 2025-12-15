extends Area2D

var active = false

func _ready():
	# Upewnij się, że monitoring jest włączony
	monitoring = true 

func _on_body_entered(body):
	# Sprawdzamy czy checkpoint jest nieaktywny i czy wszedł gracz
	if not active and body.is_in_group("player"):
		activate(body)

func activate(body):
	active = true
	print("Checkpoint aktywowany!")
		
	var level_name = ""
		
	if owner != null:
			# scene_file_path zwraca "res://scenes/levels/level_01.tscn" (małe litery)
		level_name = owner.scene_file_path.get_file().get_basename()
	else:
			# Jeśli testujesz samą scenę bez ownera
		#level_name = "level_01" 
		
		# Wymuszamy małe litery dla spójności
		level_name = level_name.to_lower()
		
	print("Zapisuję Checkpoint dla poziomu: ", level_name)
		
	GameState.activate_checkpoint(global_position, level_name)
	modulate = Color(0, 1, 0)
