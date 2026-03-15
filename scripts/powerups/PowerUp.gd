class_name PowerUp
extends Area3D

const DESPAWN_TIME: float = 30.0
const POWERUP_NAMES: Dictionary = {
	"max_ammo": "MAX AMMO",
	"nuke": "NUKE",
	"double_points": "DOUBLE POINTS",
	"insta_kill": "INSTA KILL",
}

@export var powerup_type: String = "max_ammo"

var _timer: float = DESPAWN_TIME

@onready var label: Label3D = $Label3D

func _ready():
	body_entered.connect(_on_body_entered)
	label.text = POWERUP_NAMES.get(powerup_type, powerup_type.to_upper())

func _process(delta: float):
	_timer -= delta
	if _timer <= 5.0:
		visible = int(_timer * 4) % 2 == 0
	if _timer <= 0.0:
		queue_free()

func _on_body_entered(body: Node):
	if body is PlayerController:
		GameManager.activate_powerup(powerup_type)
		queue_free()
