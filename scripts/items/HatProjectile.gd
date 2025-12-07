extends Area2D

@export var speed: float = 700.0
@export var gravity_strength: float = 700.0
@export var lifetime: float = 3.0
@export var damage: int = 30

var velocity: Vector2 = Vector2.ZERO
var direction: int = 1

@onready var sprite: Sprite2D = $Sprite2D  # upewnij się, że Sprite2D istnieje w scenie

func launch(start_pos: Vector2, dir: int) -> void:
	global_position = start_pos
	direction = dir
	velocity = Vector2(speed * direction, -250)
	set_physics_process(true)
	sprite.visible = true  # upewniamy się, że sprite jest widoczny

func _ready() -> void:
	set_physics_process(false)
	sprite.visible = false  # początkowo niewidoczna
	if lifetime > 0:
		var t = get_tree().create_timer(lifetime)
		t.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocity.y += gravity_strength * delta
	global_position += velocity * delta
	sprite.position = Vector2.ZERO  # sprite zawsze w centrum Area2D

	for body in get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
			return
