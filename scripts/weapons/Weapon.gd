extends Node3D

signal fired()
signal reloaded()
signal ammo_changed(current: int, max: int)

@export var weapon_name: String = "Pistol"
@export var damage: int = 25
@export var fire_rate: float = 0.5
@export var reload_time: float = 2.0
@export var mag_size: int = 8
@export var max_ammo: int = 64

var current_ammo: int = 8
var reserve_ammo: int = 64
var is_reloading: bool = false
var fire_timer: float = 0.0
var owner_player: PlayerController = null

@onready var shoot_origin = $ShootOrigin

func _ready():
    current_ammo = mag_size
    reserve_ammo = max_ammo - mag_size
    ammo_changed.emit(current_ammo, reserve_ammo + current_ammo)

func equip(player: PlayerController):
    owner_player = player

func _process(delta):
    fire_timer -= delta

    if is_reloading:
        return

    if Input.is_action_pressed("shoot") and fire_timer <= 0:
        fire()

    if Input.is_action_just_pressed("reload"):
        reload()

func fire():
    if current_ammo <= 0 or is_reloading:
        return

    fire_timer = fire_rate
    current_ammo -= 1
    fired.emit()

    # Raycast for hit detection
    var space_state = get_world_3d().direct_space_state
    var from = shoot_origin.global_position
    var to = from + -shoot_origin.global_transform.basis.z * 100

    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1 << 2  # Zombie layer

    var result = space_state.intersect_ray(query)

    if result:
        var collider = result["collider"]
        if collider and collider.has_method("take_damage"):
            var player_id = owner_player.player_id if owner_player else 0
            collider.take_damage(damage, "body", player_id)

    EventBus.emit_weapon_fired(owner_player.player_id, weapon_name)
    ammo_changed.emit(current_ammo, reserve_ammo + current_ammo)

func reload():
    if is_reloading or current_ammo >= mag_size or reserve_ammo <= 0:
        return

    is_reloading = true
    reloaded.emit()

    await get_tree().create_timer(reload_time).timeout

    var ammo_needed = mag_size - current_ammo
    var ammo_to_add = min(ammo_needed, reserve_ammo)

    current_ammo += ammo_to_add
    reserve_ammo -= ammo_to_add
    is_reloading = false

    EventBus.emit_weapon_reloaded(owner_player.player_id, weapon_name)
    ammo_changed.emit(current_ammo, reserve_ammo + current_ammo)

func add_ammo(amount: int):
    reserve_ammo += amount
    ammo_changed.emit(current_ammo, reserve_ammo + current_ammo)
