extends Control

@onready var btn_continue = $VBoxContainer/BtnContinue
@onready var btn_exit = $VBoxContainer/BtnExit

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func _on_continue_pressed():
	get_tree().paused = false
	hide()

func _on_exit_pressed():
	get_tree().paused = false
	get_node("/root/Main/SceneManager").goto_menu()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # czyli ESC
		_on_continue_pressed()
