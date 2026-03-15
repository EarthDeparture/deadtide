extends CanvasLayer

@onready var health_label: Label = $Control/HealthLabel
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
@onready var perks_label: Label = $Control/PerksLabel
@onready var headshot_label: Label = $Control/HeadshotLabel

var _connected_weapon: Node = null

const FLASH_ALPHA: float = 0.4
const FLASH_FADE_SPEED: float = 2.0
const ROUND_BANNER_DURATION: float = 3.0

var _flash_alpha: float = 0.0
var _headshot_alpha: float = 0.0
const HEADSHOT_FADE_SPEED: float = 1.5

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
		health_label.text = "HEALTH\n%d" % player.current_health
	EventBus.headshot_hit.connect(_on_headshot_hit)

	if GameManager.players.size() > 0:
		var pid: int = GameManager.players[0].get_instance_id()
		points_label.text = "POINTS\n%d" % GameManager.get_player_points(pid)

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
	_update_powerup_label()

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

func _on_player_damaged(_player_id: int, _damage: int, current_health: int):
	health_label.text = "HEALTH\n%d" % current_health
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

func _on_perk_bought(_perk_name: String) -> void:
	_update_perks_label()

func _update_perks_label() -> void:
	var player = get_node_or_null("/root/Main/Player")
	if player == null:
		return
	const PERK_ABBR: Dictionary = {
		"juggernaut": "JUG", "speed_cola": "SPEED",
		"quick_revive": "QR", "double_tap": "2TAP", "stamin_up": "STMN"
	}
	var parts: Array[String] = []
	for perk in player.perks:
		if PERK_ABBR.has(perk):
			parts.append(PERK_ABBR[perk])
	perks_label.text = " | ".join(parts)
	perks_label.visible = parts.size() > 0

func _connect_weapon(weapon: Node3D) -> void:
	if _connected_weapon != null and is_instance_valid(_connected_weapon) and _connected_weapon is Weapon:
		var old_w := _connected_weapon as Weapon
		if old_w.ammo_changed.is_connected(_on_ammo_changed):
			old_w.ammo_changed.disconnect(_on_ammo_changed)
		if old_w.reloaded.is_connected(_on_reload_started):
			old_w.reloaded.disconnect(_on_reload_started)
	_connected_weapon = weapon
	if weapon is Weapon:
		var w := weapon as Weapon
		w.ammo_changed.connect(_on_ammo_changed)
		w.reloaded.connect(_on_reload_started)
		_on_ammo_changed(w.current_ammo, w.reserve_ammo)
