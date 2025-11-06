extends Area2D

@export var ects_value: int = 1

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	GameState.add_ects(ects_value)
	queue_free()
