class_name PlayerController
extends CharacterBody3D

signal damaged(damage: int, health: int)
signal died()

const GRAVITY = 9.8
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

var current_health: int = 100
var max_health: int = 100
var player_id: int = 0

@export var sensitivity: float = 0.003

var current_weapon = null
var weapons: Array = []
var mouse_captured: bool = false

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head

func _ready():
	player_id = get_instance_id()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true
	GameManager.add_player(self)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		mouse_captured = !mouse_captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

	if not mouse_captured:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x

	input_dir = input_dir.normalized()

	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed

	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	EventBus.emit_player_damaged(player_id, amount, current_health)
	damaged.emit(amount, current_health)
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)

func die():
	died.emit()
	GameManager.set_player_downed(player_id, true)

func add_weapon(weapon: Node):
	weapons.append(weapon)
	if current_weapon == null:
		equip_weapon(weapon)

func equip_weapon(weapon: Node):
	if current_weapon != null:
		current_weapon.visible = false
	current_weapon = weapon
	current_weapon.visible = true
