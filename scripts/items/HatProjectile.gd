extends CharacterBody2D

@export var speed: float = 700.0
@export var gravity_strength: float = 500.0
@export var damage: int = 30

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	set_physics_process(false)
	sprite.visible = false
	
func launch(start_pos: Vector2, direction: int) -> void:
	global_position = start_pos
	velocity = Vector2(speed * direction, -250)
	
	if direction == -1:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	set_physics_process(true)
	sprite.visible = true

func _physics_process(delta: float) -> void:
	velocity.y += gravity_strength * delta
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		
		if body.is_in_group("player"):
			continue

		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
			return
		
		else:
			var t = get_tree().create_timer(1.0)
			t.timeout.connect(queue_free)
