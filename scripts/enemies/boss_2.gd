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
var is_attacking: bool = false 
var is_hurt := false
var is_dying := false
var player : CharacterBody2D

var hurt_interrupt_id: int = 0 
var electric_shock_player
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea

func _ready() -> void:
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
			anim.flip_h = false
			direction = -1
			$AttackArea/CollisionShape2D.position.x = -abs($AttackArea/CollisionShape2D.position.x)
			$ElectricArc.position.x = -abs($ElectricArc.position.x)
		else:
			anim.flip_h = true
			direction = 1
			$AttackArea/CollisionShape2D.position.x = abs($AttackArea/CollisionShape2D.position.x)
			$ElectricArc.position.x = abs($ElectricArc.position.x)
			
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
	electric_shock_player = AudioManager.play_sfx("sfx/electric-shock")
	while anim.frame < 12:
		if anim.animation != "special_attack" or player_in_range: 
			$ElectricArc.visible = false
			electric_shock_player.stop()
			return 
			
		if anim.frame == 6:
			$ElectricArc.visible = true
		else:
			$ElectricArc.visible = false
		await get_tree().process_frame	
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
		if anim.frame >= 13 and anim.frame <= 15 and not damage_dealt:
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
