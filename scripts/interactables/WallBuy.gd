class_name WallBuy
extends Interactable

@export var weapon_scene: PackedScene
@export var weapon_name: String = "M1 Carbine"
@export var weapon_cost: int = 500
@export var ammo_cost: int = 250
@export var ammo_amount: int = 30

func get_prompt(player: PlayerController = null) -> String:
	if player != null:
		for w in player.weapons:
			if w is Weapon and (w as Weapon).weapon_name == weapon_name:
				return "Press F: BUY AMMO (%s) - %dpts" % [weapon_name, ammo_cost]
	return "Press F: %s - %dpts" % [weapon_name, weapon_cost]

func interact(player: PlayerController) -> void:
	# Already own this gun — refill ammo
	for w in player.weapons:
		if w is Weapon and (w as Weapon).weapon_name == weapon_name:
			if GameManager.spend_player_points(player.player_id, ammo_cost):
				(w as Weapon).add_ammo(ammo_amount)
			else:
				EventBus.emit_purchase_denied(player.player_id)
			return

	# Don't own it yet — buy the gun
	if weapon_scene == null:
		return
	if not GameManager.spend_player_points(player.player_id, weapon_cost):
		EventBus.emit_purchase_denied(player.player_id)
		return

	var new_weapon: Node3D = weapon_scene.instantiate() as Node3D
	new_weapon.position = Vector3(0.3, -0.3, -0.5)
	player.get_node("Head/Camera3D").add_child(new_weapon)
	if new_weapon is Weapon:
		(new_weapon as Weapon).weapon_name = weapon_name
		(new_weapon as Weapon).equip(player)
	player.buy_weapon(new_weapon)
