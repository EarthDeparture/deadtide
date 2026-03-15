extends Node

signal zombie_spawned(zombie: Node)
signal zombie_killed(zombie: Node, player_id: int, points: int)
signal all_zombies_dead()

const KILL_POINTS = 100
const HEADSHOT_POINTS = 100
const KNIFE_POINTS = 130

var active_zombies: Array = []
var zombie_scene: PackedScene
var spawn_points: Array = []

func _ready():
	print("ZombieManager initialized")
	zombie_scene = preload("res://scenes/enemies/Zombie.tscn")

func register_spawn_point(spawn_point: Node3D):
	spawn_points.append(spawn_point)

func spawn_wave(round_number: int):
	var zombie_count := 6 + (4 * round_number)
	print("Spawning wave of ", zombie_count, " zombies for round ", round_number)
	for i in range(zombie_count):
		_spawn_zombie()
		await get_tree().create_timer(0.5).timeout

func _spawn_zombie():
	if spawn_points.is_empty():
		print("Warning: No spawn points registered!")
		return
	var spawn_point := spawn_points.pick_random() as Node3D
	var zombie = zombie_scene.instantiate()
	zombie.global_position = spawn_point.global_position
	get_tree().current_scene.add_child(zombie)
	active_zombies.append(zombie)
	zombie.killed.connect(_on_zombie_killed)
	zombie_spawned.emit(zombie)

func _on_zombie_killed(zombie: Node, damage_type: String, player_id: int):
	var points := KILL_POINTS
	if damage_type == "headshot":
		points = HEADSHOT_POINTS
	elif damage_type == "knife":
		points = KNIFE_POINTS
	zombie_killed.emit(zombie, player_id, points)
	GameManager.add_player_points(player_id, points)
	active_zombies.erase(zombie)
	if active_zombies.is_empty() and GameManager.round_in_progress:
		print("All zombies dead — ending round")
		all_zombies_dead.emit()
		GameManager.end_round()

func clear_all_zombies():
	for zombie in active_zombies:
		if is_instance_valid(zombie):
			zombie.queue_free()
	active_zombies.clear()
