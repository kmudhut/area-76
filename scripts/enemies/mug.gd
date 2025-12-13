extends CharacterBody2D
@export var speed: float = 700.0
@export var gravity_strength: float = 500.0
@export var damage: int = 30
var direction := -1
const SPEED = 300.0

func _ready() -> void:
	velocity = Vector2(speed * direction, -250)
	
func _physics_process(delta: float) -> void:
	velocity.y += gravity_strength * delta
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		
		if body.is_in_group("enemy"):
			continue

		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
			return
		
		else:
			var t = get_tree().create_timer(1.0)
			t.timeout.connect(queue_free)
