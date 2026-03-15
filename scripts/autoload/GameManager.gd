extends Node

signal round_started(round_number: int)
signal round_ended(round_number: int)
signal player_points_changed(player_id: int, points: int)
signal game_started()
signal game_over()

var current_round: int = 1
var players: Array[Node] = []
var game_active: bool = false
var round_in_progress: bool = false
var player_data: Dictionary = {}

func _ready():
	print("GameManager initialized")

func start_game():
	game_active = true
	current_round = 1
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
	await get_tree().create_timer(10.0).timeout
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

func revive_player(player_id: int, reviver_id: int):
	if player_data.has(player_id):
		player_data[player_id]["is_downed"] = false
		player_data[player_id]["has_revived"] = true
		EventBus.player_revived.emit(player_id, reviver_id)

func check_game_over():
	var all_downed: bool = true
	for player in players:
		var pid: int = (player as Node).get_instance_id()
		if player_data.has(pid) and not player_data[pid]["is_downed"]:
			all_downed = false
			break
	if all_downed and players.size() > 0:
		game_active = false
		game_over.emit()
