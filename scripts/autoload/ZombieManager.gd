extends Node

signal zombie_spawned(zombie: Node)
signal zombie_killed(zombie: Node, player_id: int, points: int)
signal all_zombies_dead()

const KILL_POINTS = 100
const HEADSHOT_POINTS = 100
const KNIFE_POINTS = 130
const HIT_POINTS: int = 10
const POWERUP_DROP_CHANCE: float = 0.1

var active_zombies: Array[Node] = []
var zombie_scene: PackedScene
var _powerup_scene: PackedScene
var spawn_points: Array[Node3D] = []

func _ready():
	print("ZombieManager initialized")
	zombie_scene = preload("res://scenes/enemies/Zombie.tscn")
	_powerup_scene = preload("res://scenes/powerups/PowerUp.tscn")

func register_spawn_point(spawn_point: Node3D):
	spawn_points.append(spawn_point)

func spawn_wave(round_number: int):
	var zombie_count: int = 6 + (4 * round_number)
	print("Spawning ", zombie_count, " zombies for round ", round_number)
	for i in range(zombie_count):
		_spawn_zombie()
		await get_tree().create_timer(0.5).timeout

func _spawn_zombie():
	if spawn_points.is_empty():
		for sp in get_tree().get_nodes_in_group("spawn_points"):
			spawn_points.append(sp as Node3D)
	if spawn_points.is_empty():
		print("Warning: No spawn points found!")
		return
	var spawn_point: Node3D = spawn_points.pick_random()
	var zombie: Node3D = zombie_scene.instantiate() as Node3D
	zombie.position = spawn_point.global_position
	get_tree().current_scene.add_child(zombie)
	zombie.set_round_difficulty(GameManager.current_round)
	if GameManager.players.size() > 0:
		zombie.set_target(GameManager.players[0] as Node3D)
	active_zombies.append(zombie)
	zombie.killed.connect(_on_zombie_killed)
	zombie.hit.connect(_on_zombie_hit)
	zombie_spawned.emit(zombie)

func _on_zombie_hit(_zombie: Node, _damage_type: String, player_id: int) -> void:
	GameManager.add_player_points(player_id, HIT_POINTS)

func _on_zombie_killed(zombie: Node, damage_type: String, player_id: int):
	var points: int = KILL_POINTS
	if damage_type == "headshot":
		points = HEADSHOT_POINTS
	elif damage_type == "knife":
		points = KNIFE_POINTS
	if GameManager.double_points_active:
		points *= 2
	zombie_killed.emit(zombie, player_id, points)
	GameManager.add_player_points(player_id, points)
	if randf() < POWERUP_DROP_CHANCE:
		var zombie_3d := zombie as Node3D
		if zombie_3d != null:
			_spawn_powerup(zombie_3d.global_position)
	active_zombies.erase(zombie)
	if active_zombies.is_empty() and GameManager.round_in_progress:
		print("All zombies dead - ending round")
		all_zombies_dead.emit()
		GameManager.end_round()

func _spawn_powerup(pos: Vector3):
	var types: Array = ["max_ammo", "nuke", "double_points", "insta_kill"]
	var powerup: Node3D = _powerup_scene.instantiate() as Node3D
	powerup.powerup_type = types[randi() % types.size()]
	powerup.position = pos + Vector3(0, 0.5, 0)
	get_tree().current_scene.add_child(powerup)

func nuke_all():
	if active_zombies.is_empty():
		return
	for zombie in active_zombies:
		if is_instance_valid(zombie):
			zombie.queue_free()
	active_zombies.clear()
	if GameManager.round_in_progress:
		all_zombies_dead.emit()
		GameManager.end_round()

func clear_all_zombies():
	for zombie in active_zombies:
		if is_instance_valid(zombie):
			zombie.queue_free()
	active_zombies.clear()
