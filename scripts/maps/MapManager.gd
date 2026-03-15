extends Node

signal door_opened(door_id: String, player_id: int)

var doors: Dictionary = {}  # door_id -> { cost, is_open, target_area }
var doors_node: Node3D

func _ready():
    # Find doors in the scene
    doors_node = get_tree().current_scene.find_child("Doors", true, false)
    if doors_node:
        for door in doors_node.get_children():
            if door.has_method("register_door"):
                door.register_door(self)

func register_door(door_id: String, cost: int, target_area: Area3D, door_node: Node):
    doors[door_id] = {
        "cost": cost,
        "is_open": false,
        "target_area": target_area,
        "door_node": door_node
    }

func try_open_door(player: PlayerController, door_id: String) -> bool:
    if not door_id in doors:
        print("Door not found: ", door_id)
        return false

    var door_data = doors[door_id]

    if door_data["is_open"]:
        print("Door already open: ", door_id)
        return false

    var player_id = player.player_id
    if not GameManager.spend_player_points(player_id, door_data["cost"]):
        print("Not enough points to open door: ", door_id)
        return false

    # Open the door
    door_data["is_open"] = true
    door_data["door_node"].open()

    # Enable the target area (add zombie spawn points)
    if door_data["target_area"]:
        door_data["target_area"].monitoring = true
        for spawn_point in door_data["target_area"].get_children():
            if spawn_point.has_method("enable"):
                spawn_point.enable()

    door_opened.emit(door_id, player_id)
    print("Door opened: ", door_id, " by player ", player_id)
    return true

func get_door_cost(door_id: String) -> int:
    if door_id in doors:
        return doors[door_id]["cost"]
    return -1

func is_door_open(door_id: String) -> bool:
    if door_id in doors:
        return doors[door_id]["is_open"]
    return false
