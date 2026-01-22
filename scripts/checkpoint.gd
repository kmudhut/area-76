extends Area2D

@export var checkpoint_id: String = ""

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
		
	if owner != null and owner.scene_file_path != "":
		level_name = owner.scene_file_path.get_file().get_basename()
	else:
		level_name = level_name
		
	var final_id = checkpoint_id
	if final_id == "":
		final_id = name
		
	print("Zapisuję Checkpoint: ", final_id, " dla poziomu: ", level_name)
		
	GameState.activate_checkpoint(global_position, level_name, final_id)
	modulate = Color(0, 1, 0)
	get_tree().call_group("hud", "show_save_popup")
