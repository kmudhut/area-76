extends CharacterBody2D
const MathTestScene = preload("res://scenes/ui/MathTest.tscn")
var speed: float = 1000.0
var gravity_strength: float = 1800.0
var damage: int = 30
var x_direction := -1
var y_direction := 0
var player_pos
func _ready() -> void:
	#gravity_strength = randi_range(750, 2250)
	gravity_strength = player_pos.x
	speed = randi_range(750, 1000)
	y_direction = randi_range(-150,150)
	
	velocity = Vector2(speed * x_direction, y_direction)
	
func _physics_process(delta: float) -> void:
	velocity.y += gravity_strength * delta
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		
		if body.is_in_group("enemy"):
			continue

		if body.is_in_group("player") and body.has_method("take_damage"):
			var math_test_scene = MathTestScene.instantiate()
			self.get_parent().add_child(math_test_scene)
			queue_free()
			return
		
		else:
			var t = get_tree().create_timer(1.0)
			t.timeout.connect(queue_free)
