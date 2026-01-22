extends AnimatableBody2D

# Zamiast szukać węzła po nazwie, eksportujemy go.
# Dzięki temu inne windy (które nie mają animacji) nie wywołają błędu.
@export var anim: AnimationPlayer

# To jest Twój przełącznik. Domyślnie wyłączony.
# Włączysz go tylko dla tej jednej, konkretnej windy w Inspektorze.
@export var trigger_on_stand: bool = false 

var activated := false

func _on_area_2d_body_entered(body):
	# 1. Najpierw sprawdzamy, czy ta winda w ogóle ma reagować na stanie
	if not trigger_on_stand:
		return
	
	# 2. Sprawdzamy czy już nie jedzie
	if activated:
		return

	# 3. Sprawdzamy czy to gracz i czy mamy przypisaną animację
	if body.is_in_group("player"):
		if anim:
			activated = true
			anim.play("new_animation")
		else:
			print("Brakuje przypisanego AnimationPlayer w Inspektorze!")
