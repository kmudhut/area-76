extends CharacterBody2D

const MugScene = preload("res://scenes/characters/mug.tscn")
var mug_spawned := false
var health_points = 100
var attack_cooldown := 1.0 
var direction := 1

var player_in_range: bool = false
var is_attacking: bool = false 
var is_hurt := false
var is_dying := false
var mug
var player : CharacterBody2D
@onready var spawn_offset_x = $MugSpawnPoint.position.x

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	
	if player:
		if player.global_position.x < self.global_position.x:
			$AnimatedSprite2D.flip_h = true
			direction = -1
			$MugSpawnPoint.position.x = -abs(spawn_offset_x)
		else:
			$AnimatedSprite2D.flip_h = false
			direction = 1
			$MugSpawnPoint.position.x = abs(spawn_offset_x)
	
func spawn_mug():
	mug = MugScene.instantiate()
	mug.scale = Vector2(0.04, 0.04)
	mug.global_position = $MugSpawnPoint.global_position
	mug.direction = direction
	self.get_parent().add_child(mug)
	mug_spawned = true

func attack_sequence():
	if is_attacking: return
	is_attacking = true
	
	while player_in_range:
		$AnimatedSprite2D.play("attack")
		while $AnimatedSprite2D.frame != 16:
			if $AnimatedSprite2D.animation != "attack":
				is_attacking = false
				return
			await $AnimatedSprite2D.frame_changed
		spawn_mug()
		
		await $AnimatedSprite2D.animation_finished
		$AnimatedSprite2D.play("idle")
		
		if player_in_range: 
			await get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false
	$AnimatedSprite2D.play("idle")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if(body.is_in_group("player")):
		player_in_range = true
		attack_sequence()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if(body.is_in_group("player")):
		player_in_range = false 
		

func take_damage(amount: float):
	health_points -= amount
	await play_hurt_effects()
	if health_points <= 0:
		_die()
	

func play_hurt_effects():
	if is_hurt: return
	is_hurt = true
	$AnimatedSprite2D.play("hurt")
	AudioManager.play_sfx("sfx/swot_hurt")
	await $AnimatedSprite2D.animation_finished
	if not is_dying:
		is_hurt = false 
		$AnimatedSprite2D.play("idle")

func _die():
	is_dying = true
	queue_free()
