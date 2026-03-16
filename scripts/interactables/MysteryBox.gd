class_name MysteryBox
extends Interactable

@export var weapon_scenes: Array[PackedScene] = []
@export var cost: int = 950

func get_prompt() -> String:
	return "Press F: Mystery Box - %dpts" % cost

func interact(player: PlayerController) -> void:
	if weapon_scenes.is_empty():
		return
	if not GameManager.spend_player_points(player.player_id, cost):
		EventBus.emit_purchase_denied(player.player_id)
		return
	var scene: PackedScene = weapon_scenes.pick_random()
	var new_weapon: Node3D = scene.instantiate() as Node3D
	new_weapon.position = Vector3(0.3, -0.3, -0.5)
	player.camera.add_child(new_weapon)
	if new_weapon is Weapon:
		(new_weapon as Weapon).equip(player)
	player.replace_weapon(player.current_weapon, new_weapon)
	var wname: String = (new_weapon as Weapon).weapon_name if new_weapon is Weapon else ""
	EventBus.emit_mystery_box_used(player.player_id)
	EventBus.emit_weapon_purchased(player.player_id, wname, cost)
