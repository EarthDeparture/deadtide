class_name PlayerController
extends CharacterBody3D

signal damaged(damage: int, health: int)
signal died()
signal interact_prompt_changed(text: String)
signal weapon_equipped(weapon: Node3D)

const GRAVITY: float = 9.8
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5

var current_health: int = 100
var max_health: int = 100
var player_id: int = 0
var is_dead: bool = false
var perks: Array[String] = []
var nearby_interactable: Node = null

@export var sensitivity: float = 0.003

var current_weapon: Node3D = null
var weapons: Array[Node3D] = []
var mouse_captured: bool = false

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var weapon: Weapon = $Head/Camera3D/BaseWeapon
@onready var interact_area: Area3D = $InteractArea

func _ready():
	player_id = get_instance_id()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true
	GameManager.add_player(self)
	add_weapon(weapon)
	weapon.equip(self)
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)

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
	if Input.is_action_just_pressed("interact") and nearby_interactable != null:
		nearby_interactable.interact(self)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x

	input_dir = input_dir.normalized()

	var speed: float = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
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
	current_health = mini(current_health + amount, max_health)

func die():
	if is_dead:
		return
	is_dead = true
	died.emit()
	GameManager.set_player_downed(player_id, true)
	set_process(false)
	set_physics_process(false)
	set_process_input(false)

func add_weapon(weapon: Node3D):
	weapons.append(weapon)
	if current_weapon == null:
		equip_weapon(weapon)

func equip_weapon(weapon: Node3D):
	if current_weapon != null:
		current_weapon.visible = false
	current_weapon = weapon
	current_weapon.visible = true
	weapon_equipped.emit(weapon)

func _on_interact_area_entered(area: Area3D) -> void:
	var parent: Node = area.get_parent()
	if parent != null and parent.has_method("get_prompt"):
		nearby_interactable = parent
		interact_prompt_changed.emit(parent.get_prompt())

func _on_interact_area_exited(area: Area3D) -> void:
	var parent: Node = area.get_parent()
	if parent == nearby_interactable:
		nearby_interactable = null
		interact_prompt_changed.emit("")

func buy_perk(perk_name: String) -> void:
	if perks.has(perk_name):
		return
	perks.append(perk_name)
	match perk_name:
		"juggernaut":
			max_health = 200
			current_health = 200
			damaged.emit(0, current_health)
		"speed_cola":
			if current_weapon is Weapon:
				(current_weapon as Weapon).reload_time *= 0.5
		"quick_revive":
			pass
