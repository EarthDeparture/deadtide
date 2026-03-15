class_name Door
extends Interactable

signal opened()

@export var cost: int = 750
@export var label: String = "Open Door"

func get_prompt() -> String:
	return "Press F: %s - %dpts" % [label, cost]

func interact(player: PlayerController) -> void:
	if GameManager.spend_player_points(player.player_id, cost):
		opened.emit()
		queue_free()
