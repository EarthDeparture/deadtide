class_name PerkMachine
extends Interactable

@export var perk_name: String = "juggernaut"
@export var cost: int = 2500

const PERK_DISPLAY: Dictionary = {
	"juggernaut":   "Juggernaut",
	"quick_revive": "Quick Revive",
	"speed_cola":   "Speed Cola",
	"double_tap":   "Double Tap",
	"stamin_up":    "Stamin-Up",
}

const PERK_COLOR: Dictionary = {
	"juggernaut":   Color(0.9, 0.2, 0.1),
	"quick_revive": Color(0.1, 0.4, 0.9),
	"speed_cola":   Color(0.1, 0.75, 0.2),
	"double_tap":   Color(0.9, 0.5, 0.1),
	"stamin_up":    Color(0.8, 0.8, 0.1),
}

func _ready() -> void:
	var display: String = PERK_DISPLAY.get(perk_name, perk_name.capitalize())
	var label := get_node_or_null("Label3D") as Label3D
	if label:
		label.text = "%s\n%dpts" % [display, cost]
	var mesh_inst := get_node_or_null("MachineMesh") as MeshInstance3D
	if mesh_inst and PERK_COLOR.has(perk_name):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = PERK_COLOR[perk_name]
		mesh_inst.set_surface_override_material(0, mat)

func get_prompt(_player: PlayerController = null) -> String:
	var display: String = PERK_DISPLAY.get(perk_name, perk_name.capitalize())
	return "Press F: %s - %dpts" % [display, cost]

func interact(player: PlayerController) -> void:
	if player.perks.has(perk_name):
		return
	if GameManager.spend_player_points(player.player_id, cost):
		player.buy_perk(perk_name)
		EventBus.emit_perk_purchased(player.player_id, perk_name, cost)
	else:
		EventBus.emit_purchase_denied(player.player_id)
