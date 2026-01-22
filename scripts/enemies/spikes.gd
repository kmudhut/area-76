extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $AnimatedSprite2D/Area2D

@export var time_to_stay_out: float = 1
@export var time_to_stay_in: float = 2.0 

var spikes_out: bool = false
var state_timer: Timer
var hearable = false

func _ready() -> void:
	state_timer = Timer.new()
	state_timer.one_shot = true
	state_timer.timeout.connect(_on_timer_timeout)
	add_child(state_timer)
	to_idle_mode()

func _on_timer_timeout() -> void:
	if spikes_out:
		to_idle_mode()
	else:
		to_attack_mode()

func to_attack_mode() -> void:
	if hearable:
		AudioManager.play_sfx("sfx/steel-blade-slice-2")
	spikes_out = true
	sprite.play("show_spikes")
	attack_area.monitoring = true
	
	state_timer.wait_time = time_to_stay_out
	state_timer.start()

func to_idle_mode() -> void:
	if hearable:
		AudioManager.play_sfx("sfx/steel-blade-slice-1")
	spikes_out = false
	sprite.play("hide_spikes")
	attack_area.monitoring = false
	
	state_timer.wait_time = time_to_stay_in
	state_timer.start()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.is_in_group("player")):
		body.take_damage(10)


func _on_sound_area_body_entered(body: Node2D) -> void:
	if(body.is_in_group("player")):
		hearable = true


func _on_sound_area_body_exited(body: Node2D) -> void:
	if(body.is_in_group("player")):
		hearable = false
