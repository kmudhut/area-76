extends CharacterBody2D

@export var BASE_SPEED: float = 500.0
@onready var hat_scene = preload("res://scenes/items/HatProjectile.tscn")

var current_speed: float = BASE_SPEED
const JUMP_VELOCITY: float = -850.0
const STANDARD_ATTACK_INTERVAL: float = 1.5
const KEYBOARD_ATTACK_INTERVAL: float = 2.5

var standard_attack_cooldown: float = 0.0
var keyboard_attack_cooldown: float = 0.0
var last_facing_left: bool = false

var is_attacking: bool = false
var is_attacking2: bool = false
var is_distance_attacking: bool = false
var is_hurt: bool = false

var is_invincible: bool = false
var can_use_llm_item: bool = true

var original_sprite_position_x: float = 0.0
var original_sprite_position_y: float = 0.0
var footstep_cooldown: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.3 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var motivation_component = $MotivationComponent

var rainbow_material: ShaderMaterial
var was_attacking_before_hurt: bool = false

func _ready() -> void:
	# --- TWOJA ORYGINALNA INICJALIZACJA ---
	current_speed = BASE_SPEED
	original_sprite_position_y = animated_sprite_2d.position.y
	original_sprite_position_x = animated_sprite_2d.position.x

	# Naprawa pętli animacji (to, co robiliśmy wcześniej)
	for anim in ["attack", "attack2", "hurt", "distanceattack"]:
		if animated_sprite_2d.sprite_frames.has_animation(anim):
			animated_sprite_2d.sprite_frames.set_animation_loop(anim, false)

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	
	if motivation_component:
		motivation_component.damage_taken.connect(_on_damage_taken_visuals)
		motivation_component.motivation_depleted.connect(_on_death)
	
	_setup_visual_effects_shader()
	# --- NOWE: OBSŁUGA CHECKPOINTU ---
	if GameState.last_checkpoint_position != Vector2.ZERO:
		
		var level_name = ""
		
		if owner != null:
			# Pobieramy nazwę z pliku
			level_name = owner.scene_file_path.get_file().get_basename()
		else:
			level_name = get_parent().name
					
		print("DEBUG GRACZ: Jestem na mapie: ", level_name, " | Zapis jest z mapy: ", GameState.current_level_name)
				
				# ZMIANA TUTAJ: Porównujemy obie nazwy zamienione na małe litery (.to_lower())
				# To sprawi, że "Level_01" i "level_01" będą traktowane jako to samo!
		if level_name.to_lower() == GameState.current_level_name.to_lower():
			print("SUKCES! Przenoszę gracza na checkpoint.")
			global_position = GameState.last_checkpoint_position
		else:
			print("Gracz: Nazwy map się różnią. Ignoruję.")


func _physics_process(delta: float) -> void:
	# Odliczanie cooldownów
	if footstep_cooldown > 0.0: footstep_cooldown -= delta
	if keyboard_attack_cooldown > 0.0: keyboard_attack_cooldown -= delta
	if standard_attack_cooldown > 0.0: standard_attack_cooldown -= delta

	# Blokada ruchu podczas ataku/rzutu/rany
	if is_attacking or is_attacking2 or is_distance_attacking or is_hurt:
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	check_item_input()

	# Skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Animacja w powietrzu lub na ziemi
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jump"
	else:
		if abs(velocity.x) > 10:
			animated_sprite_2d.animation = "run"
			if footstep_cooldown <= 0.0:
				AudioManager.play_sfx("sfx/footstep" + str(randi_range(1, 3)))
				footstep_cooldown = FOOTSTEP_INTERVAL
		else:
			animated_sprite_2d.animation = "idle"

	# Ruch poziomy
	var input_dir := Input.get_axis("left", "right")
	if input_dir != 0:
		velocity.x = input_dir * current_speed
		last_facing_left = input_dir < 0
		if last_facing_left:
			$AttackArea/CollisionShape2D.position.x = -abs($AttackArea/CollisionShape2D.position.x)
			$AttackArea/CollisionShape2D2.position.x = -abs($AttackArea/CollisionShape2D2.position.x)
		else:
			$AttackArea/CollisionShape2D.position.x = abs($AttackArea/CollisionShape2D.position.x)
			$AttackArea/CollisionShape2D2.position.x = abs($AttackArea/CollisionShape2D2.position.x)
	else:
		velocity.x = move_toward(velocity.x, 0, 60)

	# Ataki
	if Input.is_action_just_pressed("attack") and standard_attack_cooldown <= 0.0:
		attack1()
		standard_attack_cooldown = STANDARD_ATTACK_INTERVAL

	if Input.is_action_just_pressed("attack2") and keyboard_attack_cooldown <= 0.0:
		attack2()
		keyboard_attack_cooldown = KEYBOARD_ATTACK_INTERVAL

	if Input.is_action_just_pressed("hurt"):
		take_damage(10.0)

	if Input.is_action_just_pressed("distanceattack"):
		throw_hat()

	move_and_slide()
	animated_sprite_2d.flip_h = last_facing_left

# --- ITEMY ---
func check_item_input():
	var lb_pressed = Input.is_action_pressed("bumper_left")
	var rb_pressed = Input.is_action_pressed("bumper_right")
	if lb_pressed and rb_pressed and can_use_llm_item:
		use_llm_powerup()
		can_use_llm_item = false
	if not (lb_pressed and rb_pressed):
		can_use_llm_item = true

func use_llm_powerup():
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.use_llm_charge():
		var duration = 6.5
		is_invincible = true
		if motivation_component:
			motivation_component.heal_percent(100.0)
		apply_speed_boost(duration, 1.4)
		AudioManager.play_sfx("sfx/powerup")
		play_visual_effect(1, duration)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_llm_powerup(false)
		await get_tree().create_timer(duration).timeout
		is_invincible = false

# --- ANIMACJE ---
func _setup_visual_effects_shader():
	var code = """
	shader_type canvas_item;
	uniform int mode = 0;
	void fragment() {
		vec4 tex_color = texture(TEXTURE, UV);
		if (mode > 0 && tex_color.a > 0.0) {
			vec3 final_color = tex_color.rgb;
			if (mode == 1) {
				float wave = TIME * 4.0 - UV.y * 4.0;
				final_color = mix(tex_color.rgb, vec3(0.5 + 0.5 * sin(wave), 0.5 + 0.5 * sin(wave + 2.0), 0.5 + 0.5 * sin(wave + 4.0)), 0.6);
			} else if (mode == 2) {
				vec3 gold = vec3(1.0, 0.85, 0.3); 
				float flash = 0.5 + 0.5 * sin(TIME * 10.0); 
				vec3 bright_gold = mix(gold, vec3(1.0,1.0,1.0), flash * 0.5);
				final_color = mix(tex_color.rgb, bright_gold, 0.7);
			}
			COLOR.rgb = final_color;
			COLOR.a = tex_color.a;
		} else { COLOR = tex_color; }
	}
	"""
	var shader = Shader.new()
	shader.code = code
	rainbow_material = ShaderMaterial.new()
	rainbow_material.shader = shader
	animated_sprite_2d.material = rainbow_material

func play_visual_effect(mode_id: int, duration: float):
	if rainbow_material:
		rainbow_material.set_shader_parameter("mode", mode_id)
		await get_tree().create_timer(duration).timeout
		rainbow_material.set_shader_parameter("mode", 0)

func apply_speed_boost(duration: float, multiplier: float):
	current_speed = BASE_SPEED * multiplier
	await get_tree().create_timer(duration).timeout
	current_speed = BASE_SPEED

func take_damage(amount: float):
	if is_invincible:
		return
	if motivation_component:
		motivation_component.take_damage(amount)
	else:
		_on_damage_taken_visuals(amount)

func _on_damage_taken_visuals(_amount):
	if is_hurt: return
	was_attacking_before_hurt = is_attacking or is_attacking2 or is_distance_attacking
	is_attacking = false
	is_attacking2 = false
	is_distance_attacking = false
	is_hurt = true
	velocity.x = 0
	animated_sprite_2d.play("hurt")
	AudioManager.play_sfx("sfx/hurt" + str(randi_range(1,6)))

func _on_animation_finished():
	match animated_sprite_2d.animation:
		"attack":
			is_attacking = false
			animated_sprite_2d.position.y = original_sprite_position_y
			animated_sprite_2d.play("idle")
		"attack2":
			is_attacking2 = false
			animated_sprite_2d.position = Vector2(original_sprite_position_x, original_sprite_position_y)
			animated_sprite_2d.play("idle")
		"hurt":
			is_hurt = false
			if was_attacking_before_hurt:
				is_distance_attacking = true
				animated_sprite_2d.play("distanceattack")
			else:
				animated_sprite_2d.play("idle")
			was_attacking_before_hurt = false
		"distanceattack":
			is_distance_attacking = false
			animated_sprite_2d.position = Vector2(original_sprite_position_x, original_sprite_position_y)
			animated_sprite_2d.play("idle")

func _on_death():
	set_physics_process(false)
	AudioManager.stop_music()
	visible = false
	

func attack1():
	is_attacking = true
	$AttackArea/CollisionShape2D.disabled = false
	$AttackArea/CollisionShape2D2.disabled = true
	AudioManager.play_sfx("sfx/punch")
	velocity.x = 0
	animated_sprite_2d.play("attack")
	animated_sprite_2d.position.y = original_sprite_position_y + 20
	for body in $AttackArea.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(25)

func attack2():
	is_attacking2 = true
	$AttackArea/CollisionShape2D.disabled = true
	$AttackArea/CollisionShape2D2.disabled = false
	AudioManager.play_sfx("sfx/punch")
	velocity.x = 0
	animated_sprite_2d.play("attack2")
	animated_sprite_2d.position = Vector2(original_sprite_position_x, original_sprite_position_y)
	for body in $AttackArea.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(50)

func throw_hat():
	if is_distance_attacking:
		return
	is_distance_attacking = true

	velocity.x = 0
	animated_sprite_2d.play("distanceattack")

	# --- EARLY THROW (0.15s po rozpoczęciu animacji) ---
	await get_tree().create_timer(0.35).timeout

	var hat = hat_scene.instantiate()
	get_tree().current_scene.add_child(hat)

	var offset = Vector2(50, -10)
	if last_facing_left:
		hat.launch(global_position - offset, -1)
	else:
		hat.launch(global_position + offset, 1)

	# --- POZWÓL DOKOŃCZYĆ ANIMACJĘ ---
	await animated_sprite_2d.animation_finished

	is_distance_attacking = false
