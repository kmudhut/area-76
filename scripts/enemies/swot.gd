extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ATTACK_COOLDOWN = 2.0

var player: CharacterBody2D
var is_running = false
var can_attack = true
var footstep_cooldown := 0.0
const FOOTSTEP_INTERVAL := 0.4 

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if footstep_cooldown > 0.0: 
		footstep_cooldown -= delta
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
	if global_position.distance_to(target_position) > 150:
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
	$AnimatedSprite2D.play("attack")
	await $AnimatedSprite2D.animation_finished
	if $AttackArea.overlaps_body(player) and player.has_method("take_damage"):
		AudioManager.play_sfx("sfx/book_hit")
		player.take_damage(1)
	$AnimatedSprite2D.play("idle")
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true
