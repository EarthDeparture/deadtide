extends CharacterBody3D

signal damaged(damage: int, health: int)
signal died()
signal weapon_changed(new_weapon: Weapon)

const GRAVITY = 9.8
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

var current_health: int = 100
var max_health: int = 100
var player_id: int = get_instance_id()

@export var sensitivity: float = 0.003
@export var mouse_captured: bool = false

var current_weapon: Weapon = null
var weapons: Array = []

@onready var camera = $Camera3D
@onready var head = $Head

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    mouse_captured = true
    GameManager.add_player(self)

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        mouse_captured = !mouse_captured
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

    if not mouse_captured:
        return

    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * sensitivity)
        camera.rotate_x(-event.relative.y * sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
    # Apply gravity
    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Movement
    var input_dir = Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
        input_dir -= transform.basis.z
    if Input.is_action_pressed("move_backward"):
        input_dir += transform.basis.z
    if Input.is_action_pressed("move_left"):
        input_dir -= transform.basis.x
    if Input.is_action_pressed("move_right"):
        input_dir += transform.basis.x

    input_dir = input_dir.normalized()

    # Sprint
    var speed = WALK_SPEED
    if Input.is_key_pressed(KEY_SHIFT):
        speed = SPRINT_SPEED

    velocity.x = input_dir.x * speed
    velocity.z = input_dir.z * speed

    move_and_slide()

func take_damage(damage: int):
    current_health -= damage
    EventBus.emit_player_damaged(player_id, damage, current_health)
    damaged.emit(damage, current_health)

    if current_health <= 0:
        die()

func heal(amount: int):
    current_health = min(current_health + amount, max_health)
    EventBus.emit_player_healed(player_id, amount, current_health)

func die():
    died.emit()
    GameManager.set_player_downed(player_id, true)

func equip_weapon(weapon: Weapon):
    if current_weapon:
        current_weapon.visible = false

    current_weapon = weapon
    current_weapon.visible = true
    current_weapon.equip(self)
    weapon_changed.emit(weapon)

func add_weapon(weapon: Weapon):
    weapons.append(weapon)
    if not current_weapon:
        equip_weapon(weapon)
