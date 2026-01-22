extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ATTACK_COOLDOWN = 1.25
const FOOTSTEP_INTERVAL := 0.4 

var player: CharacterBody2D
var is_running = false
var can_attack = true
var footstep_cooldown := 0.0
var health_points = 100

var is_hurt = false 
var is_dying = false

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_dying or is_hurt:
		velocity.x = 0 
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if footstep_cooldown > 0.0: 
		footstep_cooldown -= delta
	
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		
	if player:
		if $VisibleOnScreenNotifier2D.is_on_screen():
			_move_to_player(delta)
		else:
			velocity.x = 0
			if can_attack:
				$AnimatedSprite2D.play("idle")
	
	move_and_slide()

func _move_to_player(delta):
	var target_position = player.global_position
	if target_position.x > global_position.x:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
		
	if global_position.distance_to(target_position) > 100:
		if can_attack: 
			$AnimatedSprite2D.play("run")
			if footstep_cooldown <= 0.0:
				AudioManager.play_sfx("sfx/footstep" + str(randi_range(1, 3)))
				footstep_cooldown = FOOTSTEP_INTERVAL
			is_running = true
			global_position = global_position.move_toward(target_position, SPEED * delta)
	else:
		_attack()

func _attack():
	if not can_attack:
		return
	can_attack = false
	velocity.x = 0
	$AnimatedSprite2D.play("attack")
	await $AnimatedSprite2D.animation_finished
	if is_dying or is_hurt: 
		can_attack = true 
		return

	if $AttackArea.overlaps_body(player) and player.has_method("take_damage"):
		AudioManager.play_sfx("sfx/book_hit")
		player.take_damage(4)
	
	$AnimatedSprite2D.play("idle")
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

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
	velocity = Vector2.ZERO
	queue_free()
