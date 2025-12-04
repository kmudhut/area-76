extends CharacterBody2D
#dron
@export var speed := 250.0
@export var amplitude := 50.0
@export var frequency := 1.0

#atak prądem
@export var attack_duration := 1.0 
@export var attack_cooldown_time := 3.0 
@onready var arc_visual = $Arc
var is_firing := false 
var current_attack_timer := 0.0 
var current_cooldown_timer := 0.0 
var player_in_zone := false
var electro_shock_audio_player
var drone_sound_audio_player: AudioStreamPlayer
var drone_sound_audio_player_initial_volume := 0.0
var time := 0.0
var to_be_destroyed:=false

var player: Node2D
func _ready():
	drone_sound_audio_player = AudioManager.play_sfx("sfx/drone_sound")
	if drone_sound_audio_player:
		drone_sound_audio_player_initial_volume = drone_sound_audio_player.volume_db
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
func _exit_tree():
	drone_sound_audio_player.stop()
	if drone_sound_audio_player:
		drone_sound_audio_player.stop()
		drone_sound_audio_player.volume_db = drone_sound_audio_player_initial_volume
	
func _process(delta):
	var hover_offset = Vector2(
		sin(time * (frequency * 0.9)) * amplitude,
		cos(time * (frequency * 1.1)) * amplitude
	)
	var target_position = Vector2(player.global_position.x, player.global_position.y - 4000) + hover_offset
	if to_be_destroyed:
		global_position = global_position.move_toward(target_position, speed * delta)
		drone_sound_audio_player.volume_db = move_toward(drone_sound_audio_player.volume_db, -80.0, 3.0 * delta)
		if global_position.y < -1000: 
			drone_sound_audio_player.stop()
			queue_free()
		return 
	if current_cooldown_timer > 0:
		current_cooldown_timer -= delta
	if not player:
		return
	time += delta

	target_position = Vector2(player.global_position.x, player.global_position.y - 400) + hover_offset
	global_position = global_position.move_toward(target_position, speed * delta)
	if is_firing:
		_handle_firing_state(delta)
	else:
		_handle_idle_state()

func _handle_firing_state(delta):
	if not player_in_zone:
		_finish_attack()
		return
	current_attack_timer += delta
	if player.has_method("take_damage"):
		player.take_damage(0.1) 

	if current_attack_timer >= attack_duration:
		_finish_attack()

func _handle_idle_state():
	if player_in_zone and current_cooldown_timer <= 0:
		_start_attack()

func _start_attack():
	is_firing = true
	current_attack_timer = 0.0
	
	if arc_visual:
		arc_visual.visible = true
		electro_shock_audio_player = AudioManager.play_sfx("sfx/electro_shock")


func _finish_attack():
	_stop_effects()
	current_cooldown_timer = attack_cooldown_time

func _stop_effects():
	is_firing = false
	if arc_visual:
		arc_visual.visible = false
		if electro_shock_audio_player:
			electro_shock_audio_player.stop()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_zone = false

func fly_away():
	to_be_destroyed = true
	_stop_effects()
