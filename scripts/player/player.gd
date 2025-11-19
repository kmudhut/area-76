extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
var last_facing_left = false
var is_attacking = false
var is_attacking2 = false
var is_hurt = false
var original_sprite_position_x = 0.0
var original_sprite_position_y = 0.0

var footstep_cooldown := 0.0
const FOOTSTEP_INTERVAL := 0.3 # co ile sekund można zagrać krok

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	original_sprite_position_y = animated_sprite_2d.position.y
	original_sprite_position_x = animated_sprite_2d.position.x

	if animated_sprite_2d.sprite_frames.has_animation("attack"):
		animated_sprite_2d.sprite_frames.set_animation_loop("attack", false)
	if animated_sprite_2d.sprite_frames.has_animation("attack2"):
		animated_sprite_2d.sprite_frames.set_animation_loop("attack2", false)
	if animated_sprite_2d.sprite_frames.has_animation("hurt"):
		animated_sprite_2d.sprite_frames.set_animation_loop("hurt", false)

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_attacking or is_attacking2 or is_hurt:
		move_and_slide()
		return

	# Skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Grawitacja / idle / run
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

	# 🔥 E — atak, przesunięcie w dół
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		AudioManager.play_sfx("sfx/punch")
		velocity.x = 0
		animated_sprite_2d.play("attack")
		animated_sprite_2d.position.y = original_sprite_position_y + 20

	# 🔥🌀 Q — przesunięcie zależne od kierunku + 2px w dół
	if Input.is_action_just_pressed("attack2"):
		is_attacking2 = true
		velocity.x = 0
		animated_sprite_2d.play("attack2")

		# ➤ kierunek X
		if last_facing_left:
			animated_sprite_2d.position.x = original_sprite_position_x - 105
		else:
			animated_sprite_2d.position.x = original_sprite_position_x + 105

		# ➤ przesunięcie Y (2px w dół)
		animated_sprite_2d.position.y = original_sprite_position_y + 2

	# Hurt
	if Input.is_action_just_pressed("hurt"):
		is_hurt = true
		AudioManager.play_sfx("sfx/hurt" + str(randi_range(1,6)))
		velocity.x = 0
		animated_sprite_2d.play("hurt")

	move_and_slide()

	# Obrót
	animated_sprite_2d.flip_h = last_facing_left


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
