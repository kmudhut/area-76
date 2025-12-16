extends Area2D

var active = false

func _ready():
	monitoring = true 

func _on_body_entered(body):
	if not active and body.is_in_group("player"):
		activate(body)

func activate(body):
	active = true
	print("Checkpoint aktywowany!")
		
	var level_name = ""
		
	if owner != null:
		level_name = owner.scene_file_path.get_file().get_basename()
	else:		
		# Wymuszamy małe litery dla spójności
		level_name = level_name.to_lower()
		
	print("Zapisuję Checkpoint dla poziomu: ", level_name)
		
	GameState.activate_checkpoint(global_position, level_name)
	modulate = Color(0, 1, 0)
