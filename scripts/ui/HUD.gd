extends CanvasLayer

@onready var health_label: Label = $Control/HealthLabel
@onready var points_label: Label = $Control/PointsLabel
@onready var ammo_label: Label = $Control/AmmoLabel
@onready var round_label: Label = $Control/RoundLabel
@onready var reload_label: Label = $Control/ReloadLabel

func _ready():
	GameManager.round_started.connect(_on_round_started)
	GameManager.player_points_changed.connect(_on_points_changed)
	EventBus.player_damaged.connect(_on_player_damaged)

	round_label.text = "ROUND %d" % GameManager.current_round

	var player = get_node_or_null("/root/Main/Player")
	if player and player.current_weapon:
		player.current_weapon.ammo_changed.connect(_on_ammo_changed)
		player.current_weapon.reloaded.connect(_on_reload_started)
		_on_ammo_changed(player.current_weapon.current_ammo, player.current_weapon.reserve_ammo)

	if GameManager.players.size() > 0:
		var pid: int = GameManager.players[0].get_instance_id()
		points_label.text = "POINTS\n%d" % GameManager.get_player_points(pid)

func _on_round_started(round_number: int):
	round_label.text = "ROUND %d" % round_number

func _on_points_changed(_player_id: int, points: int):
	points_label.text = "POINTS\n%d" % points

func _on_player_damaged(_player_id: int, _damage: int, current_health: int):
	health_label.text = "HEALTH\n%d" % current_health

func _on_ammo_changed(current_ammo: int, total_ammo: int):
	ammo_label.text = "%d / %d" % [current_ammo, total_ammo]
	reload_label.visible = false

func _on_reload_started():
	reload_label.visible = true
