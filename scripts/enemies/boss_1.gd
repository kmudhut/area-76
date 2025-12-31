extends CharacterBody2D

signal boss_defeated

const TestScene = preload("res://scenes/characters/Test.tscn")
var test_spawned := false
var health_points = 1000

var attack_cooldown_time := 1.5 
var special_attack_cooldown_time := 10.0
var current_cooldown: float = 0.0

var direction := 1
var player_in_range: bool = false
var is_attacking: bool = false 
var is_hurt := false
var is_dying := false
var test
var player : CharacterBody2D

var hurt_interrupt_id: int = 0 

@onready var spawn_offset_x = $TestSpawnPoint.position.x
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea

func _ready() -> void:
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	if current_cooldown > 0:
		current_cooldown -= delta

	if player and not is_dying and not is_hurt and not is_attacking:
		if player.global_position.x < self.global_position.x:
			anim.flip_h = true
			direction = -1
			$TestSpawnPoint.position.x = -abs(spawn_offset_x)
			$AttackArea/CollisionShape2D.position.x = -abs($AttackArea/CollisionShape2D.position.x)
		else:
			anim.flip_h = false
			direction = 1
			$TestSpawnPoint.position.x = abs(spawn_offset_x)
			$AttackArea/CollisionShape2D.position.x = abs($AttackArea/CollisionShape2D.position.x)

	if not is_attacking and not is_hurt and not is_dying:
		if current_cooldown <= 0:
			decide_combat()

func decide_combat():
	if player_in_range:
		perform_attack()
	else:
		perform_special_attack()

func perform_special_attack():
	if is_attacking: 
		return
	is_attacking = true
	anim.play("special_attack")
	while anim.frame < 12:
		if anim.animation != "special_attack": 
			return 
		if player_in_range:
			return 
		await get_tree().process_frame
	spawn_test()
	await anim.animation_finished
	
	if anim.animation != "special_attack":
		return
	anim.play("idle")
	is_attacking = false
	current_cooldown = special_attack_cooldown_time

func perform_attack():
	if is_attacking and anim.animation == "attack": return
	is_attacking = true
	anim.play("attack")
	var damage_dealt = false 
	while anim.is_playing() and anim.animation == "attack":
		if anim.animation != "attack":
			return
		if anim.frame >= 6 and anim.frame <= 11 and not damage_dealt:
			if attack_area.overlaps_body(player):
				if player.has_method("take_damage"):
					AudioManager.play_sfx("sfx/book_hit")
					player.take_damage(5)
					# --- NOWY FRAGMENT: ODRZUT ---
					if player.has_method("apply_knockback"):
						# direction to kierunek bossa (-1 lewo, 1 prawo).
						# Mnożymy * 400 (siła w bok) i dodajemy -250 (siła w górę).
						var kick_vector = Vector2(direction * 800, -250)
						player.apply_knockback(kick_vector)
					# -----------------------------
					damage_dealt = true
		await get_tree().process_frame
	anim.play("idle")
	is_attacking = false
	
	current_cooldown = attack_cooldown_time

func spawn_test():
	test = TestScene.instantiate()
	test.scale = Vector2(0.175, 0.175)
	test.global_position = $TestSpawnPoint.global_position
	test.direction = direction
	self.get_parent().add_child(test)
	test_spawned = true

func _on_attacking_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

		if is_attacking and anim.animation == "attack":
			return
			
		is_attacking = false 
		current_cooldown = 0.0 
		perform_attack()

func _on_attacking_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false 

func take_damage(amount: float):
	health_points -= amount
	if health_points <= 0:
		_die()
		return
	play_hurt_effects()

func play_hurt_effects():
	is_attacking = false 
	is_hurt = true
	hurt_interrupt_id += 1
	var my_interrupt_id = hurt_interrupt_id
	
	anim.stop()
	anim.play("hurt")
	AudioManager.play_sfx("sfx/swot_hurt")
	
	await anim.animation_finished
	
	if hurt_interrupt_id == my_interrupt_id and not is_dying:
		is_hurt = false 
		anim.play("idle")
		
func _die():
	is_dying = true
	$AnimatedSprite2D.play("die")
	emit_signal("boss_defeated")
	await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(1.0).timeout
	queue_free()
