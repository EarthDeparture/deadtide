extends Node

signal round_started(round_number: int)
signal round_ended(round_number: int)
signal round_countdown(seconds_remaining: int)
signal player_points_changed(player_id: int, points: int)
signal game_started()
signal game_over()
signal powerup_activated(type: String, duration: float)
signal powerup_expired(type: String)

var current_round: int = 1
var players: Array[Node] = []
var game_active: bool = false
var round_in_progress: bool = false
var player_data: Dictionary = {}

var double_points_active: bool = false
var insta_kill_active: bool = false
var double_points_timer: float = 0.0
var insta_kill_timer: float = 0.0

const POWERUP_DURATION: float = 30.0

func _ready():
	print("GameManager initialized")

func _process(delta: float):
	if double_points_active:
		double_points_timer -= delta
		if double_points_timer <= 0.0:
			double_points_active = false
			powerup_expired.emit("double_points")
	if insta_kill_active:
		insta_kill_timer -= delta
		if insta_kill_timer <= 0.0:
			insta_kill_active = false
			powerup_expired.emit("insta_kill")

func activate_powerup(type: String):
	match type:
		"max_ammo":
			for player in players:
				if player.has_method("refill_all_ammo"):
					player.refill_all_ammo()
			powerup_activated.emit("max_ammo", 0.0)
		"nuke":
			for player in players:
				if is_instance_valid(player):
					add_player_points(player.get_instance_id(), 400)
			ZombieManager.nuke_all()
			powerup_activated.emit("nuke", 0.0)
		"double_points":
			double_points_active = true
			double_points_timer = POWERUP_DURATION
			powerup_activated.emit("double_points", POWERUP_DURATION)
		"insta_kill":
			insta_kill_active = true
			insta_kill_timer = POWERUP_DURATION
			powerup_activated.emit("insta_kill", POWERUP_DURATION)

func reset() -> void:
	game_active = false
	round_in_progress = false
	current_round = 1
	players.clear()
	player_data.clear()
	double_points_active = false
	insta_kill_active = false
	double_points_timer = 0.0
	insta_kill_timer = 0.0

func start_game():
	game_active = true
	current_round = 1
	double_points_active = false
	insta_kill_active = false
	double_points_timer = 0.0
	insta_kill_timer = 0.0
	game_started.emit()
	start_round()

func start_round():
	if not game_active:
		return
	round_in_progress = true
	print("Starting round ", current_round)
	round_started.emit(current_round)
	ZombieManager.spawn_wave(current_round)

func end_round():
	if not game_active:
		return
	round_in_progress = false
	round_ended.emit(current_round)
	current_round += 1
	for i in range(10, 0, -1):
		if not game_active:
			return
		round_countdown.emit(i)
		await get_tree().create_timer(1.0).timeout
	start_round()

func add_player(player: Node):
	var player_id: int = player.get_instance_id()
	players.append(player)
	player_data[player_id] = {
		"points": 500,
		"is_downed": false,
		"has_revived": false
	}

func get_player_points(player_id: int) -> int:
	if player_data.has(player_id):
		return player_data[player_id]["points"]
	return 0

func add_player_points(player_id: int, amount: int):
	if player_data.has(player_id):
		player_data[player_id]["points"] += amount
		player_points_changed.emit(player_id, player_data[player_id]["points"])

func spend_player_points(player_id: int, amount: int) -> bool:
	if player_data.has(player_id):
		if player_data[player_id]["points"] >= amount:
			player_data[player_id]["points"] -= amount
			player_points_changed.emit(player_id, player_data[player_id]["points"])
			return true
	return false

func set_player_downed(player_id: int, downed: bool):
	if player_data.has(player_id):
		player_data[player_id]["is_downed"] = downed
		if downed:
			EventBus.emit_player_downed(player_id)
			check_game_over()

func revive_player(player_id: int, reviver_id: int):
	if player_data.has(player_id):
		player_data[player_id]["is_downed"] = false
		player_data[player_id]["has_revived"] = true
		EventBus.player_revived.emit(player_id, reviver_id)

func check_game_over():
	var all_downed: bool = true
	for player in players:
		if not is_instance_valid(player):
			continue
		var pid: int = (player as Node).get_instance_id()
		if player_data.has(pid) and not player_data[pid]["is_downed"]:
			all_downed = false
			break
	if all_downed and players.size() > 0:
		game_active = false
		game_over.emit()
