extends CharacterBody2D

@export var speed := 800
@export var jump_height := 400      # wysokość skoku
@export var jump_speed := 800       # prędkość skoku
var screensize := Vector2(1920, 1080)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var jumping := false
var jump_start_y := 0.0
var going_up := true

func _process(delta: float) -> void:
	var velocity := Vector2.ZERO

	# Ruch poziomy
	if Input.is_action_pressed("ui_left"):
		velocity.x = -1
	if Input.is_action_pressed("ui_right"):
		velocity.x = 1

	# Skok – jeśli nie skacze, wciśnięcie "W" lub "↑" rozpoczyna skok
	if not jumping and Input.is_action_just_pressed("ui_up"):
		jumping = true
		going_up = true
		jump_start_y = position.y
		sprite.play("jump")

	# Obsługa skoku (ruch góra–dół)
	if jumping:
		if going_up:
			position.y -= jump_speed * delta
			if position.y <= jump_start_y - jump_height:
				going_up = false
		else:
			position.y += jump_speed * delta
			if position.y >= jump_start_y:
				jumping = false
				position.y = jump_start_y

	# Animacje poziome
	if not jumping:
		if velocity.x != 0:
			if sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")

	# Odwracanie sprite’a
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	# Ruch poziomy
	position += velocity.normalized() * speed * delta

	# Ograniczenie do ekranu (opcjonalne)
	position.x = clamp(position.x, 0, screensize.x)
	position.y = clamp(position.y, 0, screensize.y)
