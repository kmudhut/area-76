<<<<<<< Updated upstream
extends Area2D

@export var ects_value: int = 1

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	GameState.add_ects(ects_value)
	queue_free()
=======
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
>>>>>>> Stashed changes
