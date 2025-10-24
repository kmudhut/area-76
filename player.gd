extends Area2D
@export var speed = 400
var velocity=Vector2.ZERO
var screensize=Vector2(1920,1080)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity=Vector2()
	if Input.is_action_pressed("ui_left"):
		velocity.x=-1
	if Input.is_action_pressed("ui_right"):
		velocity.x= 1
	if Input.is_action_pressed("ui_up"):
		velocity.y= -1
	if Input.is_action_pressed("ui_down"):
		velocity.y= 1
	
	# velocity(x,y)
	position += velocity *speed*delta
	
	position.x=clamp(position.x,0,screensize.x)
	position.y=clamp(position.y,0,screensize.y)
