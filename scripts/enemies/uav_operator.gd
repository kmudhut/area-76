extends CharacterBody2D

const DroneScene = preload("res://scenes/characters/drone.tscn")
var drone_spawned := false
var detection_distance := 1150.0

func _physics_process(delta):
	if drone_spawned:
		return
	for player in get_tree().get_nodes_in_group("player"):
		var dist = global_position.distance_to(player.global_position)
		if dist <= detection_distance:
			print("W DYSTANSIE")
			$AnimatedSprite2D.play("starting_drone")
			return 

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "starting_drone" and not drone_spawned:
		spawn_drone()
		$AnimatedSprite2D.play("after_drone_start")

func spawn_drone():
	var drone = DroneScene.instantiate()
	drone.scale = Vector2(0.25, 0.25)
	drone.global_position = $DroneSpawnPoint.global_position
	get_tree().current_scene.add_child(drone)
	drone_spawned = true
	print("Dron spawned at: ", drone.global_position)
