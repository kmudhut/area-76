extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
var last_facing_left = false
var is_attacking = false
var is_hurt = false
var original_sprite_position_y = 0.0

var footstep_cooldown := 0.0
const FOOTSTEP_INTERVAL := 0.3 # co ile sekund można zagrać krok

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Zapamiętaj oryginalną pozycję sprite’a
	original_sprite_position_y = animated_sprite_2d.position.y

	# Wyłącz pętlę animacji "attack" i "hurt" (na wszelki wypadek)
	if animated_sprite_2d.sprite_frames.has_animation("attack"):
		animated_sprite_2d.sprite_frames.set_animation_loop("attack", false)
	if animated_sprite_2d.sprite_frames.has_animation("hurt"):
		animated_sprite_2d.sprite_frames.set_animation_loop("hurt", false)

	# Po zakończeniu dowolnej animacji uruchom tę funkcję
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	# Odliczanie cooldownu kroków
	if footstep_cooldown > 0.0:
		footstep_cooldown -= delta

	# Jeśli trwa atak lub hurt – blokuj ruch i animacje
	if is_attacking or is_hurt:
		move_and_slide()
		return

	# Skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Grawitacja
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jump"
	else:
		if abs(velocity.x) > 10:
			animated_sprite_2d.animation = "run"
			# Odtwarzaj krok tylko, jeśli minął cooldown
			if footstep_cooldown <= 0.0:
				AudioManager.play_sfx("sfx/footstep" + str(randi_range(1, 3)))
				footstep_cooldown = FOOTSTEP_INTERVAL
		else:
			animated_sprite_2d.animation = "idle"

	# Ruch poziomy
	var direction := Input.get_axis("left", "right")

	if direction != 0:
		velocity.x = direction * SPEED
		last_facing_left = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, 60)

	# Atak (E)
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		AudioManager.play_sfx("sfx/punch")
		velocity.x = 0
		animated_sprite_2d.play("attack")
		# przesuwamy animację w dół o 20 pikseli
		animated_sprite_2d.position.y = original_sprite_position_y + 20

	# Damage / Hurt (H)
	if Input.is_action_just_pressed("hurt"):
		is_hurt = true
		AudioManager.play_sfx("sfx/hurt" + str(randi_range(1,6)))
		velocity.x = 0
		animated_sprite_2d.play("hurt")

	move_and_slide()

	# Obrót sprite’a
	animated_sprite_2d.flip_h = last_facing_left


# Gdy animacja się skończy
func _on_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack":
		is_attacking = false
		animated_sprite_2d.play("idle")
		animated_sprite_2d.position.y = original_sprite_position_y

	if animated_sprite_2d.animation == "hurt":
		is_hurt = false
		animated_sprite_2d.play("idle")
