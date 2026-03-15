class_name Weapon
extends Node3D

signal fired()
signal reloaded()
signal ammo_changed(current_ammo: int, total_ammo: int)

@export var weapon_name: String = "Pistol"
@export var damage: int = 25
@export var fire_rate: float = 0.5
@export var reload_time: float = 2.0
@export var mag_size: int = 8
@export var max_reserve: int = 56

var current_ammo: int = 0
var reserve_ammo: int = 0
var is_reloading: bool = false
var fire_timer: float = 0.0
var owner_player: PlayerController = null
var _base_reload_time: float = -1.0
var _base_fire_rate: float = -1.0
var _dry_fire_timer: float = 0.0

@export var spread: float = 0.03
@export var recoil_amount: float = 0.03

@onready var shoot_origin: Node3D = $ShootOrigin
@onready var _muzzle_light: OmniLight3D = get_node_or_null("ShootOrigin/MuzzleLight")

func _ready():
	_base_reload_time = reload_time
	_base_fire_rate = fire_rate
	current_ammo = mag_size
	reserve_ammo = max_reserve
	ammo_changed.emit(current_ammo, reserve_ammo)

func equip(player: PlayerController):
	owner_player = player

func _process(delta: float):
	_dry_fire_timer = maxf(_dry_fire_timer - delta, 0.0)
	fire_timer = maxf(fire_timer - delta, 0.0)

	if is_reloading:
		return

	if Input.is_action_pressed("shoot") and fire_timer <= 0.0:
		fire()

	if Input.is_action_just_pressed("reload"):
		reload()

func fire():
	if current_ammo <= 0 or is_reloading:
		if current_ammo <= 0 and not is_reloading and owner_player != null and _dry_fire_timer <= 0.0:
			EventBus.emit_weapon_dry_fired(owner_player.player_id)
			_dry_fire_timer = 0.5
		return

	fire_timer = fire_rate
	current_ammo -= 1
	fired.emit()

	var space_state := get_world_3d().direct_space_state
	var from := shoot_origin.global_position
	var forward := -shoot_origin.global_transform.basis.z
	var spread_offset := Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		0.0
	)
	var to := from + (forward + spread_offset) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 2

	var result := space_state.intersect_ray(query)
	if result and result.collider.has_method("take_damage"):
		var pid := owner_player.player_id if owner_player != null else 0
		var actual_damage: int = 99999 if GameManager.insta_kill_active else damage
		var damage_type: String = "body"
		if result.position.y > result.collider.global_position.y + 1.2:
			damage_type = "headshot"
			EventBus.emit_headshot_hit(pid)
		result.collider.take_damage(actual_damage, damage_type, pid)
		EventBus.emit_hit_registered(pid, damage_type == "headshot")

	if owner_player != null:
		EventBus.emit_weapon_fired(owner_player.player_id, weapon_name)
		owner_player.apply_recoil(recoil_amount)

	if _muzzle_light:
		_muzzle_light.visible = true
		await get_tree().process_frame
		if is_instance_valid(_muzzle_light):
			_muzzle_light.visible = false

	ammo_changed.emit(current_ammo, reserve_ammo)

func reload():
	if is_reloading or current_ammo >= mag_size or reserve_ammo <= 0:
		return
	is_reloading = true
	reloaded.emit()
	await get_tree().create_timer(reload_time).timeout
	var needed := mag_size - current_ammo
	var to_add: int = mini(needed, reserve_ammo)
	current_ammo += to_add
	reserve_ammo -= to_add
	is_reloading = false
	if owner_player != null:
		EventBus.emit_weapon_reloaded(owner_player.player_id, weapon_name)
	ammo_changed.emit(current_ammo, reserve_ammo)

func add_ammo(amount: int):
	reserve_ammo += amount
	ammo_changed.emit(current_ammo, reserve_ammo)

func refill_ammo():
	current_ammo = mag_size
	reserve_ammo = max_reserve
	ammo_changed.emit(current_ammo, reserve_ammo)
