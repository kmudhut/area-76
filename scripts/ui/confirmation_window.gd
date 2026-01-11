extends CanvasLayer

signal confirmed
signal cancelled

@onready var panel = $Panel

func _ready():
	panel.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_no_button_pressed()

func _on_yes_button_pressed():
	confirmed.emit()
	close_popup()

func _on_no_button_pressed():
	cancelled.emit()
	close_popup()

func close_popup():
	queue_free()
