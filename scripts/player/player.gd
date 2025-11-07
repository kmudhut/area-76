extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
var last_facing_left = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Grawitacja
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jump"
	else:
		# Wybór animacji idle/run
		if abs(velocity.x) > 10:
			animated_sprite_2d.animation = "run"
		else:
			animated_sprite_2d.animation = "idle"

	# Skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Kierunek ruchu
	var direction := Input.get_axis("left", "right")

	if direction != 0:
		velocity.x = direction * SPEED
		last_facing_left = direction < 0   # zapamiętaj kierunek
	else:
		velocity.x = move_toward(velocity.x, 0, 60)

	move_and_slide()

	# Obrót sprite’a w odpowiednim kierunku
	animated_sprite_2d.flip_h = last_facing_left
