extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Control/Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Control/Panel/VBox/QuitButton.pressed.connect(_on_quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_show_menu()

func _show_menu() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()
