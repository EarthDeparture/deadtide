extends Node3D

func _ready():
	for name in ["SpawnPoint1", "SpawnPoint2", "SpawnPoint3", "SpawnPoint4"]:
		ZombieManager.register_spawn_point($SpawnPoints.get_node(name))
	$Interactables/Door1.opened.connect(_on_door1_opened)

func _on_door1_opened():
	for name in ["SpawnPoint5", "SpawnPoint6", "SpawnPoint7", "SpawnPoint8"]:
		ZombieManager.register_spawn_point($SpawnPoints.get_node(name))
