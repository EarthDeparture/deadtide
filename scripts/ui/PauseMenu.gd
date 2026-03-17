extends CanvasLayer

@onready var _main_panel: PanelContainer = $Control/MainPanel
@onready var _settings_panel: PanelContainer = $Control/SettingsPanel
@onready var _master_slider: HSlider = $Control/SettingsPanel/VBox/MasterRow/MasterSlider
@onready var _master_label: Label = $Control/SettingsPanel/VBox/MasterRow/MasterValueLabel
@onready var _render_slider: HSlider = $Control/SettingsPanel/VBox/RenderScaleRow/RenderScaleSlider
@onready var _render_label: Label = $Control/SettingsPanel/VBox/RenderScaleRow/RenderScaleValueLabel
@onready var _vsync_toggle: CheckButton = $Control/SettingsPanel/VBox/VSyncRow/VSyncToggle
@onready var _msaa_option: OptionButton = $Control/SettingsPanel/VBox/MSAARow/MSAAOption
@onready var _fps_option: OptionButton = $Control/SettingsPanel/VBox/FPSRow/FPSOption

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	$Control/MainPanel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Control/MainPanel/VBox/SettingsButton.pressed.connect(_on_open_settings)
	$Control/MainPanel/VBox/QuitButton.pressed.connect(_on_quit)
	$Control/SettingsPanel/VBox/BackButton.pressed.connect(_on_close_settings)

	# Master volume — read current bus level
	var bus_idx: int = AudioServer.get_bus_index("Master")
	var cur_db: float = AudioServer.get_bus_volume_db(bus_idx)
	_master_slider.value = clampf(db_to_linear(cur_db) * 100.0, 0.0, 100.0)
	_master_label.text = "%d%%" % int(_master_slider.value)
	_master_slider.value_changed.connect(_on_master_changed)

	# Render scale
	var rs: float = get_viewport().scaling_3d_scale
	_render_slider.value = clampf(rs * 100.0, 50.0, 100.0)
	_render_label.text = "%d%%" % int(_render_slider.value)
	_render_slider.value_changed.connect(_on_render_scale_changed)

	# VSync
	_vsync_toggle.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	_vsync_toggle.toggled.connect(_on_vsync_toggled)

	# MSAA
	_msaa_option.add_item("Off")
	_msaa_option.add_item("2x")
	_msaa_option.add_item("4x")
	_msaa_option.add_item("8x")
	match get_viewport().msaa_3d:
		Viewport.MSAA_2X: _msaa_option.selected = 1
		Viewport.MSAA_4X: _msaa_option.selected = 2
		Viewport.MSAA_8X: _msaa_option.selected = 3
		_: _msaa_option.selected = 0
	_msaa_option.item_selected.connect(_on_msaa_changed)

	# Max FPS cap
	_fps_option.add_item("Unlimited")
	_fps_option.add_item("30")
	_fps_option.add_item("60")
	_fps_option.add_item("120")
	match Engine.max_fps:
		30: _fps_option.selected = 1
		60: _fps_option.selected = 2
		120: _fps_option.selected = 3
		_: _fps_option.selected = 0
	_fps_option.item_selected.connect(_on_fps_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings_panel.visible:
			_on_close_settings()
		elif visible:
			_on_resume()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_show_menu()

func _show_menu() -> void:
	visible = true
	_main_panel.visible = true
	_settings_panel.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_open_settings() -> void:
	_main_panel.visible = false
	_settings_panel.visible = true

func _on_close_settings() -> void:
	_settings_panel.visible = false
	_main_panel.visible = true

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()

func _on_master_changed(value: float) -> void:
	_master_label.text = "%d%%" % int(value)
	var idx: int = AudioServer.get_bus_index("Master")
	if value <= 0.0:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))

func _on_render_scale_changed(value: float) -> void:
	_render_label.text = "%d%%" % int(value)
	get_viewport().scaling_3d_scale = value / 100.0

func _on_vsync_toggled(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)

func _on_msaa_changed(index: int) -> void:
	match index:
		0: get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1: get_viewport().msaa_3d = Viewport.MSAA_2X
		2: get_viewport().msaa_3d = Viewport.MSAA_4X
		3: get_viewport().msaa_3d = Viewport.MSAA_8X

func _on_fps_changed(index: int) -> void:
	match index:
		0: Engine.max_fps = 0
		1: Engine.max_fps = 30
		2: Engine.max_fps = 60
		3: Engine.max_fps = 120
