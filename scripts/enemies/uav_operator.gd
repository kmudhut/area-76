extends CharacterBody2D

const DroneScene = preload("res://scenes/characters/drone.tscn")
var drone_spawned := false
var detection_distance := 800.0
var health_points = 0.01
var drone
func _ready() -> void:
	print(self.get_parent().name)
func _physics_process(delta):
	if drone_spawned:
		return
	for player in get_tree().get_nodes_in_group("player"):
		var dist = global_position.distance_to(player.global_position)
		if dist <= detection_distance:
			$AnimatedSprite2D.play("starting_drone")
			return 

func _process(delta: float) -> void:
	pass
func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "starting_drone" and not drone_spawned:
		spawn_drone()
		$AnimatedSprite2D.play("after_drone_start")

func spawn_drone():
	drone = DroneScene.instantiate()
	drone.scale = Vector2(0.25, 0.25)
	drone.global_position = $DroneSpawnPoint.global_position
	self.get_parent().add_child(drone)
	drone_spawned = true
	
func take_damage(amount: float):
	health_points-=amount
	await play_hurt_effects()
	if(health_points <= 0):
		_die()

func play_hurt_effects():
	$AnimatedSprite2D.play("hurt")
	AudioManager.play_sfx("sfx/uav_operator_die_scream")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("after_drone_start")
	

func _die():
	drone.fly_away()
	queue_free()
