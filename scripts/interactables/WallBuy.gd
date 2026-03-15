class_name WallBuy
extends Interactable

@export var weapon_scene: PackedScene
@export var weapon_name: String = "M1 Carbine"
@export var weapon_cost: int = 500
@export var ammo_cost: int = 250
@export var ammo_amount: int = 30

func get_prompt() -> String:
	return "Press F: %s - %dpts" % [weapon_name, weapon_cost]

func interact(player: PlayerController) -> void:
	for w in player.weapons:
		if w is Weapon and (w as Weapon).weapon_name == weapon_name:
			if GameManager.spend_player_points(player.player_id, ammo_cost):
				(w as Weapon).add_ammo(ammo_amount)
			else:
				EventBus.emit_purchase_denied(player.player_id)
			return
	if weapon_scene == null:
		return
	if GameManager.spend_player_points(player.player_id, weapon_cost):
		var new_weapon: Node3D = weapon_scene.instantiate() as Node3D
		new_weapon.position = Vector3(0.3, -0.3, -0.5)
		player.get_node("Head/Camera3D").add_child(new_weapon)
		if new_weapon is Weapon:
			(new_weapon as Weapon).weapon_name = weapon_name
			(new_weapon as Weapon).equip(player)
		player.add_weapon(new_weapon)
		player.equip_weapon(new_weapon)
	else:
		EventBus.emit_purchase_denied(player.player_id)
