extends Node3D

func _ready():
	for spawn_point in $SpawnPoints.get_children():
		ZombieManager.register_spawn_point(spawn_point)
