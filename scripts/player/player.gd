extends CharacterBody2D

@export var BASE_SPEED = 500.0
var current_speed = 500.0
const JUMP_VELOCITY = -850.0

var last_facing_left = false
var is_attacking = false
var is_attacking2 = false
var is_hurt = false

# --- NOWE ZMIENNE ---
var is_invincible = false # Nieśmiertelność dla LLM
var can_use_llm_item = true # Blokada spamowania kombinacji

var original_sprite_position_x = 0.0
var original_sprite_position_y = 0.0
var footstep_cooldown := 0.0
const FOOTSTEP_INTERVAL := 0.3 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var motivation_component = $MotivationComponent

var rainbow_material: ShaderMaterial

func _ready() -> void:
	current_speed = BASE_SPEED
	original_sprite_position_y = animated_sprite_2d.position.y
	original_sprite_position_x = animated_sprite_2d.position.x

	if animated_sprite_2d.sprite_frames.has_animation("attack"):
		animated_sprite_2d.sprite_frames.set_animation_loop("attack", false)
	if animated_sprite_2d.sprite_frames.has_animation("attack2"):
		animated_sprite_2d.sprite_frames.set_animation_loop("attack2", false)
	if animated_sprite_2d.sprite_frames.has_animation("hurt"):
		animated_sprite_2d.sprite_frames.set_animation_loop("hurt", false)

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	
	if motivation_component:
		motivation_component.damage_taken.connect(_on_damage_taken_visuals)
		motivation_component.motivation_depleted.connect(_on_death)
	
	_setup_visual_effects_shader()

func _physics_process(delta: float) -> void:
	if footstep_cooldown > 0.0: footstep_cooldown -= delta

	if is_attacking or is_attacking2 or is_hurt:
		move_and_slide()
		return

	# Sprawdzanie kombinacji LB+RB dla Mocy LLM
	check_item_input()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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

	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = direction * current_speed 
		last_facing_left = direction < 0
		if last_facing_left:
			$AttackArea/CollisionShape2D.position.x = -abs($AttackArea/CollisionShape2D.position.x)
			$AttackArea/CollisionShape2D2.position.x = -abs($AttackArea/CollisionShape2D2.position.x)

		else:
			$AttackArea/CollisionShape2D.position.x = abs($AttackArea/CollisionShape2D.position.x)
			$AttackArea/CollisionShape2D2.position.x = abs($AttackArea/CollisionShape2D2.position.x)
	else:
		velocity.x = move_toward(velocity.x, 0, 60)

	if Input.is_action_just_pressed("attack"):
		#is_attacking = true
		#AudioManager.play_sfx("sfx/punch")
		#velocity.x = 0
		#animated_sprite_2d.play("attack")
		#animated_sprite_2d.position.y = original_sprite_position_y + 20
		attack1()

	if Input.is_action_just_pressed("attack2"):
		attack2()
		#is_attacking2 = true
		#velocity.x = 0
		#animated_sprite_2d.play("attack2")
		#if last_facing_left:
			#animated_sprite_2d.position.x = original_sprite_position_x - 105
		#else:
			#animated_sprite_2d.position.x = original_sprite_position_x + 105
		#animated_sprite_2d.position.y = original_sprite_position_y + 2

	if Input.is_action_just_pressed("hurt"):
		take_damage(10.0) 

	move_and_slide()
	animated_sprite_2d.flip_h = last_facing_left


# --- OBSŁUGA ITEMÓW ---

func check_item_input():
	# Sprawdzamy kombinację LB + RB (bumper_left + bumper_right)
	var lb_pressed = Input.is_action_pressed("bumper_left")
	var rb_pressed = Input.is_action_pressed("bumper_right")
	
	# Aktywacja Mocy LLM
	if lb_pressed and rb_pressed and can_use_llm_item:
		use_llm_powerup()
		can_use_llm_item = false
	
	if not (lb_pressed and rb_pressed):
		can_use_llm_item = true

func use_llm_powerup():
	var gs = get_node_or_null("/root/GameState")
	# Sprawdzamy czy mamy ładunki w GameState
	if gs and gs.use_llm_charge():
		# --- EFEKTY MOCY LLM ---
		var duration = 6.5
		
		# 1. Nieśmiertelność
		is_invincible = true
		
		# 2. NOWE: Leczenie do 100%
		if motivation_component:
			motivation_component.heal_percent(100.0)
			print("LLM: Uleczono do pełna!")
		
		apply_speed_boost(duration, 1.4)
		
		AudioManager.play_sfx("sfx/powerup")
		
		play_visual_effect(1, duration)
		
		print("Aktywowano MOC LLM! (LB+RB)")
		
		await get_tree().create_timer(duration).timeout
		is_invincible = false
		print("Koniec Mocy LLM.")

# --- EFEKTY WIZUALNE ---

func play_golden_flash_effect():
	# Uruchamiamy efekt ZŁOTA (Shader Mode 2) na 0.5 sekundy
	play_visual_effect(2, 0.5)

func _setup_visual_effects_shader():
	# Shader obsługujący dwa tryby: 1 = Tęcza, 2 = Złoto
	var code = """
	shader_type canvas_item;
	uniform int mode = 0; // 0 = Off, 1 = Rainbow, 2 = Golden
	
	void fragment() {
		vec4 tex_color = texture(TEXTURE, UV);
		
		if (mode > 0 && tex_color.a > 0.0) {
			vec3 final_color = tex_color.rgb;
			float alpha = tex_color.a;
			
			if (mode == 1) { 
				// --- TRYB 1: TĘCZA (LLM) ---
				float wave = TIME * 4.0 - UV.y * 4.0;
				float r = 0.5 + 0.5 * sin(wave);
				float g = 0.5 + 0.5 * sin(wave + 2.0);
				float b = 0.5 + 0.5 * sin(wave + 4.0);
				vec3 rainbow = vec3(r, g, b);
				final_color = mix(tex_color.rgb, rainbow, 0.6); // 60% tęczy
			
			} else if (mode == 2) {
				// --- TRYB 2: ZŁOTO (Golden Drink) ---
				// Jasny, pulsujący złoty kolor
				vec3 gold = vec3(1.0, 0.85, 0.3); 
				// Pulsowanie jasności (błysk)
				float flash = 0.5 + 0.5 * sin(TIME * 10.0); 
				vec3 bright_gold = mix(gold, vec3(1.0, 1.0, 1.0), flash * 0.5);
				final_color = mix(tex_color.rgb, bright_gold, 0.7); // 70% złota
			}
			
			COLOR.rgb = final_color;
			COLOR.a = alpha;
		} else {
			COLOR = tex_color;
		}
	}
	"""
	
	var shader = Shader.new()
	shader.code = code
	
	rainbow_material = ShaderMaterial.new()
	rainbow_material.shader = shader
	animated_sprite_2d.material = rainbow_material

func play_visual_effect(mode_id: int, duration: float):
	if rainbow_material:
		# Ustawiamy tryb (1=Tęcza, 2=Złoto)
		rainbow_material.set_shader_parameter("mode", mode_id)
		
		await get_tree().create_timer(duration).timeout
		
		# Wyłączamy (0=Off)
		rainbow_material.set_shader_parameter("mode", 0)
		

# --- RESZTA LOGIKI ---

func apply_speed_boost(duration: float, multiplier: float):
	current_speed = BASE_SPEED * multiplier
	await get_tree().create_timer(duration).timeout
	current_speed = BASE_SPEED

func take_damage(amount: float):
	if is_invincible:
		print("Uniknięto obrażeń (LLM Shield)")
		return

	if motivation_component:
		motivation_component.take_damage(amount)
	else:
		_on_damage_taken_visuals(amount)

func _on_damage_taken_visuals(_amount):
	if is_hurt: return
	if is_attacking or is_attacking2:
		is_attacking = false
		is_attacking2 = false
		animated_sprite_2d.position.x = original_sprite_position_x
		animated_sprite_2d.position.y = original_sprite_position_y
	is_hurt = true
	AudioManager.play_sfx("sfx/hurt" + str(randi_range(1,6)))
	velocity.x = 0
	animated_sprite_2d.play("hurt")

func _on_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack":
		is_attacking = false
		animated_sprite_2d.position.y = original_sprite_position_y
		animated_sprite_2d.play("idle")

	if animated_sprite_2d.animation == "attack2":
		is_attacking2 = false
		animated_sprite_2d.position.x = original_sprite_position_x
		animated_sprite_2d.position.y = original_sprite_position_y
		animated_sprite_2d.play("idle")

	if animated_sprite_2d.animation == "hurt":
		is_hurt = false
		animated_sprite_2d.play("idle")

func _on_death():
	print("Gracz stracił motywację. Restart poziomu...")
	AudioManager.stop_music()
	var scene_manager = get_node("/root/Main/SceneManager")
	scene_manager.goto_menu() # Trzeba tu zaimplementować scenę końca gry w przypadku zgonu

func attack1():
	is_attacking = true
	$AttackArea/CollisionShape2D.disabled = false
	$AttackArea/CollisionShape2D2.disabled = true
	AudioManager.play_sfx("sfx/punch")
	velocity.x = 0
	animated_sprite_2d.play("attack")
	animated_sprite_2d.position.y = original_sprite_position_y + 20
	var bodies = $AttackArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				print("Zadano uszkodzenia piescia dla", body)	
				body.take_damage(25)

func attack2():
	is_attacking2 = true
	$AttackArea/CollisionShape2D.disabled = true
	$AttackArea/CollisionShape2D2.disabled = false
	AudioManager.play_sfx("sfx/punch")
	velocity.x = 0
	animated_sprite_2d.play("attack2")
	if last_facing_left:
		animated_sprite_2d.position.x = original_sprite_position_x - 105
	else:
		animated_sprite_2d.position.x = original_sprite_position_x + 105
		animated_sprite_2d.position.y = original_sprite_position_y + 2
	var bodies = $AttackArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):	
				body.take_damage(50)
