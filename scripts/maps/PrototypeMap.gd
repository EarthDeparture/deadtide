extends Node3D

func _ready():
	# Register windows (each WindowBarricade adds itself to "barricades" group in _ready)
	for window in get_tree().get_nodes_in_group("barricades"):
		ZombieManager.register_window(window as WindowBarricade)

	# Room 2 windows start inactive — unlocked when Door1 is opened
	$Barricades/WindowNE.is_active = false
	$Barricades/WindowSE.is_active = false

	for sp_name in ["SpawnPoint1", "SpawnPoint2", "SpawnPoint3", "SpawnPoint4"]:
		ZombieManager.register_spawn_point($SpawnPoints.get_node(sp_name))
	$Interactables/Door1.opened.connect(_on_door1_opened)

func _on_door1_opened():
	$Barricades/WindowNE.is_active = true
	$Barricades/WindowSE.is_active = true
	for sp_name in ["SpawnPoint5", "SpawnPoint6", "SpawnPoint7", "SpawnPoint8"]:
		ZombieManager.register_spawn_point($SpawnPoints.get_node(sp_name))
