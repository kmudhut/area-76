extends CharacterBody2D

signal health_changed(current_hp, max_hp)
signal boss_defeated

var health_points = 200
var max_health_points = health_points

var attack_cooldown_time := 1.5 
var special_attack_cooldown_time := 10.0
var current_cooldown: float = 0.0

var direction := 1
var player_in_range: bool = false
var is_player_in_safe_zone: bool = false
var is_attacking: bool = false 
var is_hurt := false
var is_dying := false
var player : CharacterBody2D


var hurt_interrupt_id: int = 0 
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var safe_zone_area = $"../SafeZoneArea"

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	safe_zone_area.body_entered.connect(_on_safe_zone_entered)
	safe_zone_area.body_exited.connect(_on_safe_zone_exited)

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
			$AttackArea/CollisionShape2D.position.x = -abs($AttackArea/CollisionShape2D.position.x)
		else:
			anim.flip_h = false
			direction = 1
			$AttackArea/CollisionShape2D.position.x = abs($AttackArea/CollisionShape2D.position.x)
			
	if not is_attacking and not is_hurt and not is_dying:
		if current_cooldown <= 0:
			decide_combat()

func find_best_drop_point(player_pos: Vector2) -> Vector2:
	var all_points = get_tree().get_nodes_in_group("drop_points")
	var best_point = null
	var min_vertical_dist = 99999.0
	
	for point in all_points:
		var diff = point.global_position.y - player_pos.y
		
		if diff > 50.0: 
			if diff < min_vertical_dist:
				min_vertical_dist = diff
				best_point = point
	
	if best_point:
		return best_point.global_position
	return Vector2.ZERO

func decide_combat():
	if player_in_range:
		perform_attack()
	elif not is_player_in_safe_zone:
		perform_special_attack()

func perform_special_attack():
	if is_attacking or not player: 
		return
	anim.play("special_attack")
	is_attacking = true
	player.animated_sprite_2d.play("jump")
	player.is_stunned = true
	player.velocity = Vector2.ZERO
	var target_pos = find_best_drop_point(player.global_position)
	if target_pos == Vector2.ZERO:
		target_pos = player.global_position
	
	var tween = create_tween()
	
	var lift_height = player.global_position.y - 180
	tween.tween_property(player, "global_position:y", lift_height, 1.0)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_interval(0.15)
	tween.set_parallel(true)
	
	var throw_duration = 0.15 # Czas lotu
	tween.tween_property(player, "global_position:x", target_pos.x, throw_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(player, "global_position:y", target_pos.y, throw_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.set_parallel(false)
	
	tween.tween_callback(finish_special_attack)

func finish_special_attack():
	if player:
		player.is_stunned = false
		player.take_damage(20)
		
		AudioManager.play_sfx("sfx/punch") # Tu powinien być dźwięk głośnego uderzenia!
		
		# EFEKT TRZĘSIENIA KAMERĄ (Screen Shake)
		# Jeśli masz kamerę z funkcją shake, wywołaj ją tutaj:
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(5.0) # siła wstrząsu
	
	anim.play("idle")
	is_attacking = false
	current_cooldown = special_attack_cooldown_time

func _on_safe_zone_entered(body):
	if body == player:
		is_player_in_safe_zone = true
		# Opcjonalnie: Jeśli boss właśnie zaczął ładować specjał, można go przerwać
		# if is_attacking and anim.animation == "special_attack_charge": ...

func _on_safe_zone_exited(body):
	if body == player:
		is_player_in_safe_zone = false

func perform_attack():
	if is_attacking and anim.animation == "attack": return
	is_attacking = true
	anim.play("attack")
	var damage_dealt = false 
	while anim.is_playing() and anim.animation == "attack":
		if anim.animation != "attack":
			return
		if anim.frame == 5 and not damage_dealt:
			if attack_area.overlaps_body(player):
				if player.has_method("take_damage"):
					AudioManager.play_sfx("sfx/book_hit")
					player.take_damage(1)
					damage_dealt = true
		await get_tree().process_frame
	anim.play("idle")
	is_attacking = false
	
	current_cooldown = attack_cooldown_time


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
	emit_signal("health_changed", health_points, max_health_points)
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
	await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(1.0).timeout
	emit_signal("boss_defeated")
	queue_free()
