extends CharacterBody2D

@export var BASE_SPEED = 500.0
var current_speed = 500.0 
const JUMP_VELOCITY = -900.0

var last_facing_left = false
var is_attacking = false
var is_attacking2 = false
var is_hurt = false
var original_sprite_position_x = 0.0
var original_sprite_position_y = 0.0
var footstep_cooldown := 0.0
const FOOTSTEP_INTERVAL := 0.3 # co ile sekund można zagrać krok
var is_pain_cooldown := false # cooldown odtwarzania dzwieku hurta

var can_use_golden_drink = true 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var motivation_component = $MotivationComponent

# Zmienna do przechowywania naszego materiału z shaderem
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
	
	# --- NOWOŚĆ: INICJALIZACJA SHADERA ---
	_setup_rainbow_shader()

func _physics_process(delta: float) -> void:
	if footstep_cooldown > 0.0: footstep_cooldown -= delta

	if is_attacking or is_attacking2 or is_hurt:
		move_and_slide()
		return

	check_golden_drink_input() 

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
	else:
		velocity.x = move_toward(velocity.x, 0, 60)

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		AudioManager.play_sfx("sfx/punch")
		velocity.x = 0
		animated_sprite_2d.play("attack")
		animated_sprite_2d.position.y = original_sprite_position_y + 20

	if Input.is_action_just_pressed("attack2"):
		is_attacking2 = true
		velocity.x = 0
		animated_sprite_2d.play("attack2")
		if last_facing_left:
			animated_sprite_2d.position.x = original_sprite_position_x - 105
		else:
			animated_sprite_2d.position.x = original_sprite_position_x + 105
		animated_sprite_2d.position.y = original_sprite_position_y + 2

	if Input.is_action_just_pressed("hurt"):
		take_damage(10) 

	move_and_slide()
	animated_sprite_2d.flip_h = last_facing_left


# --- OBSŁUGA ZŁOTEGO NAPOJU ---

func check_golden_drink_input():
	var lb_pressed = Input.is_action_pressed("bumper_left")
	var rb_pressed = Input.is_action_pressed("bumper_right")
	
	if lb_pressed and rb_pressed and can_use_golden_drink:
		use_golden_drink()
		can_use_golden_drink = false 
	
	if not (lb_pressed and rb_pressed):
		can_use_golden_drink = true

func use_golden_drink():
	var gs = get_node_or_null("/root/GameState")
	
	if gs and gs.use_golden_drink():
		var buff_duration = 6.5
		
		if motivation_component:
			motivation_component.heal_percent(50.0)
			motivation_component.activate_defense_boost(buff_duration) 
		
		AudioManager.play_sfx("sfx/rare_use") 
		
		# Uruchamiamy efekt SHADERA zamiast Tweena koloru
		play_rainbow_shader_effect(buff_duration)
		
		print("Użyto Złotego Napoju! Efekt fali aktywny.")
	else:
		pass


func _setup_rainbow_shader():
	var code = """
	shader_type canvas_item;
	uniform bool active = false;
	
	void fragment() {
		vec4 tex_color = texture(TEXTURE, UV);
		
		if (active && tex_color.a > 0.0) {
			// Fala z góry na dół (TIME minus UV.y)
			float wave = TIME * 4.0 - UV.y * 4.0;
			
			// Generujemy tęczę z przesunięciem fazowym (czerwony, zielony, niebieski)
			float r = 0.5 + 0.5 * sin(wave);
			float g = 0.5 + 0.5 * sin(wave + 2.0);
			float b = 0.5 + 0.5 * sin(wave + 4.0);
			
			vec3 rainbow = vec3(r, g, b);
			
			// Mieszamy oryginalny kolor z tęczą (0.6 to siła efektu)
			COLOR.rgb = mix(tex_color.rgb, rainbow, 0.6);
			COLOR.a = tex_color.a;
		} else {
			COLOR = tex_color;
		}
	}
	"""
	
	var shader = Shader.new()
	shader.code = code
	
	rainbow_material = ShaderMaterial.new()
	rainbow_material.shader = shader
	
	# Przypisujemy materiał do duszka
	animated_sprite_2d.material = rainbow_material

func play_rainbow_shader_effect(duration: float):
	if rainbow_material:
		# Włączamy efekt w shaderze
		rainbow_material.set_shader_parameter("active", true)
		
		# Czekamy czas trwania buffa
		await get_tree().create_timer(duration).timeout
		
		# Wyłączamy efekt
		rainbow_material.set_shader_parameter("active", false)


# --- RESZTA FUNKCJI ---

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

func apply_speed_boost(duration: float, multiplier: float):
	current_speed = BASE_SPEED * multiplier
	await get_tree().create_timer(duration).timeout
	current_speed = BASE_SPEED

func take_damage(amount: int):
	if motivation_component:
		motivation_component.take_damage(amount)
	else:
		_trigger_hurt_effects()

func _on_death():
	print("Gracz stracił motywację. Restart poziomu...")
	var scene_manager = get_node("/root/Main/SceneManager")
	scene_manager.goto_menu() # Trzeba tu zaimplementować scenę końca gry w przypadku zgonu


func _trigger_hurt_effects():
	is_pain_cooldown = true
	is_hurt = true
	AudioManager.play_sfx("sfx/hurt" + str(randi_range(1,6)))
	velocity.x = 0
	animated_sprite_2d.play("hurt")
	await get_tree().create_timer(0.4).timeout
	is_pain_cooldown = false
	is_hurt = false
