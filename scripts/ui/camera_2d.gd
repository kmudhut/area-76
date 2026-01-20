extends Camera2D

# --- KONFIGURACJA ---
@export var decay_rate: float = 5.0
@export var max_offset: Vector2 = Vector2(10, 10)

var current_shake_strength: float = 0.0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func _process(delta: float) -> void:
	if current_shake_strength > 0:
		current_shake_strength = lerp(current_shake_strength, 0.0, decay_rate * delta)
		var random_x = rng.randf_range(-current_shake_strength, current_shake_strength)
		var random_y = rng.randf_range(-current_shake_strength, current_shake_strength)
		offset = Vector2(random_x, random_y)
		if current_shake_strength < 0.1:
			current_shake_strength = 0
			offset = Vector2.ZERO
	else:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO

func apply_shake(strength: float):
	current_shake_strength = strength
