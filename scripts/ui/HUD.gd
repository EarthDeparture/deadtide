extends CanvasLayer

@onready var points_label: Label = $Control/PointsLabel
@onready var ammo_label: Label = $Control/AmmoLabel
@onready var round_label: Label = $Control/RoundLabel
@onready var reload_label: Label = $Control/ReloadLabel
@onready var interact_label: Label = $Control/InteractLabel
@onready var damage_flash: ColorRect = $Control/DamageFlash
@onready var round_banner: Label = $Control/RoundBanner
@onready var game_over_panel: ColorRect = $Control/GameOverPanel
@onready var game_over_label: Label = $Control/GameOverPanel/GameOverContainer/GameOverLabel
@onready var play_again_button: Button = $Control/GameOverPanel/GameOverContainer/PlayAgainButton
@onready var quit_button: Button = $Control/GameOverPanel/GameOverContainer/QuitButton
@onready var powerup_label: Label = $Control/PowerupLabel
@onready var weapon_label: Label = $Control/WeaponLabel
@onready var headshot_label: Label = $Control/HeadshotLabel
@onready var blood_vignette: ColorRect = $Control/BloodVignette
@onready var hit_marker: Label = $Control/HitMarker
@onready var crosshair_top: ColorRect = $Control/CrosshairTop
@onready var crosshair_bottom: ColorRect = $Control/CrosshairBottom
@onready var crosshair_left: ColorRect = $Control/CrosshairLeft
@onready var crosshair_right: ColorRect = $Control/CrosshairRight
@onready var perks_container: HBoxContainer = $Control/PerksContainer

var _connected_weapon: Node = null

const FLASH_ALPHA: float = 0.4
const FLASH_FADE_SPEED: float = 2.0
const ROUND_BANNER_DURATION: float = 3.0
const HIT_FADE_SPEED: float = 8.0
const HEADSHOT_FADE_SPEED: float = 1.5

var _flash_alpha: float = 0.0
var _headshot_alpha: float = 0.0
var _hit_alpha: float = 0.0
var _crosshair_spread: float = 0.0
var _last_points: int = 0

const FloatingTextScene = preload("res://scenes/ui/FloatingText.tscn")

const PERK_COLORS: Dictionary = {
	"juggernaut": Color(0.8, 0.1, 0.1),
	"quick_revive": Color(0.1, 0.4, 0.9),
	"speed_cola": Color(0.1, 0.8, 0.2),
	"double_tap": Color(0.9, 0.5, 0.1),
	"stamin_up": Color(0.8, 0.8, 0.1)
}
const PERK_ABBR: Dictionary = {
	"juggernaut": "JUG", "quick_revive": "QR",
	"speed_cola": "SPD", "double_tap": "2×", "stamin_up": "STM"
}

func _ready():
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.round_countdown.connect(_on_round_countdown)
	GameManager.game_over.connect(_on_game_over)
	GameManager.powerup_activated.connect(_on_powerup_activated)
	GameManager.powerup_expired.connect(_on_powerup_expired)
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	GameManager.player_points_changed.connect(_on_points_changed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_downed.connect(_on_player_downed)
	EventBus.player_revive_tick.connect(_on_revive_tick)
	EventBus.player_revived.connect(_on_player_revived)
	EventBus.hit_registered.connect(_on_hit_registered)

	round_label.text = "ROUND %d" % GameManager.current_round

	var player = get_node_or_null("/root/Main/Player")
	if player:
		player.interact_prompt_changed.connect(_on_interact_prompt_changed)
		player.weapon_equipped.connect(_on_weapon_equipped)
		player.perk_bought.connect(_on_perk_bought)
		if player.current_weapon:
			_connect_weapon(player.current_weapon)
			if player.current_weapon is Weapon:
				weapon_label.text = (player.current_weapon as Weapon).weapon_name
		_update_vignette()
	EventBus.headshot_hit.connect(_on_headshot_hit)

	if GameManager.players.size() > 0:
		var pid: int = GameManager.players[0].get_instance_id()
		_last_points = GameManager.get_player_points(pid)
		points_label.text = "POINTS\n%d" % _last_points

func _process(delta: float):
	if _flash_alpha > 0.0:
		_flash_alpha -= FLASH_FADE_SPEED * delta
		if _flash_alpha < 0.0:
			_flash_alpha = 0.0
		damage_flash.color = Color(0.8, 0.0, 0.0, _flash_alpha)
	if _headshot_alpha > 0.0:
		_headshot_alpha = maxf(_headshot_alpha - HEADSHOT_FADE_SPEED * delta, 0.0)
		headshot_label.modulate = Color(1.0, 1.0, 0.0, _headshot_alpha)
		if _headshot_alpha <= 0.0:
			headshot_label.visible = false
	if _hit_alpha > 0.0:
		_hit_alpha = maxf(_hit_alpha - HIT_FADE_SPEED * delta, 0.0)
		hit_marker.modulate.a = _hit_alpha
		if _hit_alpha <= 0.0:
			hit_marker.visible = false
	_update_powerup_label()
	var player = get_node_or_null("/root/Main/Player")
	var move_spread: float = 0.0
	if player:
		move_spread = player.velocity.length() * 0.6
	_crosshair_spread = move_toward(_crosshair_spread, move_spread, 80.0 * delta)
	_update_crosshair(_crosshair_spread)

func _update_crosshair(spread: float) -> void:
	var gap: float = 8.0 + spread
	crosshair_top.offset_top = -(gap + 8.0)
	crosshair_top.offset_bottom = -gap
	crosshair_bottom.offset_top = gap
	crosshair_bottom.offset_bottom = gap + 8.0
	crosshair_left.offset_left = -(gap + 8.0)
	crosshair_left.offset_right = -gap
	crosshair_right.offset_left = gap
	crosshair_right.offset_right = gap + 8.0

func _update_vignette() -> void:
	var player = get_node_or_null("/root/Main/Player")
	if player == null:
		return
	var ratio: float = float(player.current_health) / float(player.max_health)
	_set_vignette_intensity(clamp(1.0 - ratio, 0.0, 1.0))

func _set_vignette_intensity(intensity: float) -> void:
	var mat := blood_vignette.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", intensity)

func _update_powerup_label():
	var parts: Array[String] = []
	if GameManager.double_points_active:
		parts.append("2X POINTS %ds" % ceili(GameManager.double_points_timer))
	if GameManager.insta_kill_active:
		parts.append("INSTA KILL %ds" % ceili(GameManager.insta_kill_timer))
	if parts.is_empty():
		powerup_label.visible = false
	else:
		powerup_label.text = "  ".join(parts)
		powerup_label.visible = true

func _on_round_started(round_number: int):
	round_label.text = "ROUND %d" % round_number
	round_banner.visible = false

func _on_round_ended(round_number: int):
	round_banner.text = "ROUND %d COMPLETE" % round_number
	round_banner.visible = true

func _on_round_countdown(seconds_remaining: int):
	round_banner.text = "NEXT ROUND IN %ds" % seconds_remaining
	round_banner.visible = true

func _on_game_over():
	var points: int = 0
	if GameManager.players.size() > 0:
		var pid: int = GameManager.players[0].get_instance_id()
		points = GameManager.get_player_points(pid)
	game_over_label.text = "GAME OVER\nRound %d\n%d pts" % [GameManager.current_round, points]
	game_over_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_powerup_activated(type: String, _duration: float):
	match type:
		"max_ammo":
			powerup_label.text = "MAX AMMO!"
			powerup_label.visible = true
			await get_tree().create_timer(2.0).timeout
			_update_powerup_label()
		"nuke":
			powerup_label.text = "NUKE!"
			powerup_label.visible = true
			await get_tree().create_timer(2.0).timeout
			_update_powerup_label()

func _on_powerup_expired(_type: String):
	_update_powerup_label()

func _on_play_again_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()

func _on_points_changed(_player_id: int, points: int):
	points_label.text = "POINTS\n%d" % points
	var delta_pts: int = points - _last_points
	_last_points = points
	if delta_pts > 0:
		var ft := FloatingTextScene.instantiate() as FloatingText
		if ft:
			$Control/FloatingTextAnchor.add_child(ft)
			ft.position = Vector2(randf_range(-20, 20), 0.0)
			ft.show_text("+%d" % delta_pts)

func _on_player_damaged(_player_id: int, _damage: int, current_health: int) -> void:
	var player = get_node_or_null("/root/Main/Player")
	var max_hp: int = player.max_health if player else 100
	var ratio: float = float(current_health) / float(max_hp)
	_set_vignette_intensity(clamp(1.0 - ratio, 0.0, 1.0))
	_flash_alpha = FLASH_ALPHA

func _on_ammo_changed(current_ammo: int, total_ammo: int):
	ammo_label.text = "%d / %d" % [current_ammo, total_ammo]
	reload_label.visible = false

func _on_reload_started():
	reload_label.visible = true

func _on_player_downed(_player_id: int):
	reload_label.text = "DOWNED - REVIVING..."
	reload_label.visible = true

func _on_revive_tick(_player_id: int, time_remaining: float):
	reload_label.text = "REVIVING IN %.1fs" % time_remaining

func _on_player_revived(_player_id: int, _reviver_id: int):
	reload_label.visible = false
	_update_vignette()

func _on_interact_prompt_changed(text: String) -> void:
	interact_label.text = text
	interact_label.visible = text != ""

func _on_weapon_equipped(weapon: Node3D) -> void:
	_connect_weapon(weapon)
	if weapon is Weapon:
		weapon_label.text = (weapon as Weapon).weapon_name

func _on_headshot_hit(_player_id: int) -> void:
	headshot_label.visible = true
	_headshot_alpha = 1.0
	headshot_label.modulate = Color(1.0, 1.0, 0.0, 1.0)

func _on_hit_registered(_player_id: int, is_headshot: bool) -> void:
	hit_marker.visible = true
	_hit_alpha = 1.0
	hit_marker.modulate = Color(1.0, 0.1, 0.1, 1.0) if is_headshot else Color(1.0, 1.0, 1.0, 1.0)

func _on_perk_bought(_perk_name: String) -> void:
	_update_perks_label()
	_update_vignette()

func _on_weapon_fired() -> void:
	_crosshair_spread = minf(_crosshair_spread + 12.0, 40.0)

func _update_perks_label() -> void:
	var player = get_node_or_null("/root/Main/Player")
	if player == null:
		return
	for child in perks_container.get_children():
		child.queue_free()
	for perk in player.perks:
		var panel := PanelContainer.new()
		var label := Label.new()
		label.text = PERK_ABBR.get(perk, "?")
		label.add_theme_font_size_override("font_size", 13)
		var style := StyleBoxFlat.new()
		style.bg_color = PERK_COLORS.get(perk, Color.WHITE)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		panel.add_theme_stylebox_override("panel", style)
		panel.add_child(label)
		perks_container.add_child(panel)
	perks_container.visible = player.perks.size() > 0

func _connect_weapon(weapon: Node3D) -> void:
	if _connected_weapon != null and is_instance_valid(_connected_weapon) and _connected_weapon is Weapon:
		var old_w := _connected_weapon as Weapon
		if old_w.ammo_changed.is_connected(_on_ammo_changed):
			old_w.ammo_changed.disconnect(_on_ammo_changed)
		if old_w.reloaded.is_connected(_on_reload_started):
			old_w.reloaded.disconnect(_on_reload_started)
		if old_w.fired.is_connected(_on_weapon_fired):
			old_w.fired.disconnect(_on_weapon_fired)
	_connected_weapon = weapon
	if weapon is Weapon:
		var w := weapon as Weapon
		w.ammo_changed.connect(_on_ammo_changed)
		w.reloaded.connect(_on_reload_started)
		w.fired.connect(_on_weapon_fired)
		_on_ammo_changed(w.current_ammo, w.reserve_ammo)
