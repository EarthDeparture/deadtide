class_name MapManager
extends Node3D

signal door_opened(door_id: String, player_id: int)

var doors: Dictionary = {}

func _ready():
	pass

func register_door(door_id: String, cost: int, door_node: Node):
	doors[door_id] = {
		"cost": cost,
		"is_open": false,
		"door_node": door_node
	}

func try_open_door(player: PlayerController, door_id: String) -> bool:
	if not doors.has(door_id):
		return false

	var door_data = doors[door_id]

	if door_data["is_open"]:
		return false

	if not GameManager.spend_player_points(player.player_id, door_data["cost"]):
		return false

	door_data["is_open"] = true
	door_data["door_node"].open()
	door_opened.emit(door_id, player.player_id)
	return true

func get_door_cost(door_id: String) -> int:
	if doors.has(door_id):
		return doors[door_id]["cost"]
	return -1

func is_door_open(door_id: String) -> bool:
	if doors.has(door_id):
		return doors[door_id]["is_open"]
	return false
