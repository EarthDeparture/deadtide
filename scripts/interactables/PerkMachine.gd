class_name PerkMachine
extends Interactable

@export var perk_name: String = "juggernaut"
@export var cost: int = 2500

func get_prompt(_player: PlayerController = null) -> String:
	return "Press F: %s - %dpts" % [perk_name.capitalize(), cost]

func interact(player: PlayerController) -> void:
	if player.perks.has(perk_name):
		return
	if GameManager.spend_player_points(player.player_id, cost):
		player.buy_perk(perk_name)
		EventBus.emit_perk_purchased(player.player_id, perk_name, cost)
	else:
		EventBus.emit_purchase_denied(player.player_id)
