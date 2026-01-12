extends AnimatableBody2D

@export_group("Ustawienia Windy")
@export var move_offset: Vector2 = Vector2(0, 500)
@export var duration: float = 6.0
@export var trigger_on_stand: bool = true

@onready var left_wall = $lewa
@onready var right_wall = $prawa

var activated: bool = false

func _on_trigger_area_body_entered(body):
	if not trigger_on_stand or activated:
		return

	if body.is_in_group("player"):
		AudioManager.stop_music()
		AudioManager.play_music("music/elevator-music")
		start_elevator()

func start_elevator():
	if activated: return
	activated = true
	left_wall.set_deferred("disabled", false)
	right_wall.set_deferred("disabled", false)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", position + move_offset, duration)
	tween.tween_callback(open_walls)

func open_walls():
	left_wall.set_deferred("disabled", true)
	right_wall.set_deferred("disabled", true)
	AudioManager.stop_music()
	AudioManager.play_music("music/big-jason-slap-house-background-music-for-video-vlog-stories-short-394175")
