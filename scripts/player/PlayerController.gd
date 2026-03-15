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

var _shake_trauma: float = 0.0
const SHAKE_DECAY: float = 4.0
const SHAKE_MAX_OFFSET: float = 0.015

var _melee_cooldown: float = 0.0
const MELEE_DAMAGE: int = 150
const MELEE_RANGE: float = 1.5
const MELEE_COOLDOWN: float = 0.6

var is_downed: bool = false
var has_quick_revive: bool = false
var _revive_timer: float = 0.0
const REVIVE_TIME: float = 5.0

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
	if is_downed:
		_revive_timer -= delta
		EventBus.player_revive_tick.emit(player_id, _revive_timer)
		if _revive_timer <= 0.0:
			_revive()
		return

	if Input.is_action_just_pressed("interact") and nearby_interactable != null:
		nearby_interactable.interact(self)

	if weapons.size() > 1:
		if Input.is_action_just_pressed("weapon_1"):
			equip_weapon(weapons[0])
		elif Input.is_action_just_pressed("weapon_2") and weapons.size() >= 2:
			equip_weapon(weapons[1])
		elif Input.is_action_just_pressed("weapon_next"):
			_cycle_weapon(1)
		elif Input.is_action_just_pressed("weapon_prev"):
			_cycle_weapon(-1)

	_melee_cooldown = maxf(_melee_cooldown - delta, 0.0)
	if Input.is_action_just_pressed("melee") and _melee_cooldown <= 0.0:
		_melee_attack()

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

	if _shake_trauma > 0.0:
		_shake_trauma = move_toward(_shake_trauma, 0.0, SHAKE_DECAY * delta)
		camera.position = Vector3(
			randf_range(-_shake_trauma, _shake_trauma) * SHAKE_MAX_OFFSET,
			randf_range(-_shake_trauma, _shake_trauma) * SHAKE_MAX_OFFSET,
			0.0
		)
	else:
		camera.position = Vector3.ZERO

	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	_shake_trauma = minf(_shake_trauma + 0.4, 1.0)
	EventBus.emit_player_damaged(player_id, amount, current_health)
	damaged.emit(amount, current_health)
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = mini(current_health + amount, max_health)

func die():
	if is_dead or is_downed:
		return
	if has_quick_revive:
		_enter_downed()
		return
	is_dead = true
	died.emit()
	GameManager.set_player_downed(player_id, true)
	set_process(false)
	set_physics_process(false)
	set_process_input(false)

func _enter_downed():
	is_downed = true
	has_quick_revive = false
	_revive_timer = REVIVE_TIME
	current_health = 1
	EventBus.emit_player_downed(player_id)
	if current_weapon:
		current_weapon.set_process(false)

func _revive():
	is_downed = false
	current_health = 50
	if current_weapon:
		current_weapon.set_process(true)
	GameManager.revive_player(player_id, player_id)
	damaged.emit(0, current_health)

func _cycle_weapon(direction: int):
	var idx: int = weapons.find(current_weapon)
	var next_idx: int = (idx + direction + weapons.size()) % weapons.size()
	equip_weapon(weapons[next_idx])

func _melee_attack():
	_melee_cooldown = MELEE_COOLDOWN
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * MELEE_RANGE)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 2  # zombie layer
	var result := space_state.intersect_ray(query)
	if result and result.collider.has_method("take_damage"):
		var actual_damage: int = 99999 if GameManager.insta_kill_active else MELEE_DAMAGE
		result.collider.take_damage(actual_damage, "knife", player_id)

func add_weapon(weapon: Node3D):
	weapons.append(weapon)
	if current_weapon == null:
		equip_weapon(weapon)

func equip_weapon(weapon: Node3D):
	if current_weapon != null:
		current_weapon.visible = false
	current_weapon = weapon
	current_weapon.visible = true
	if perks.has("speed_cola") and current_weapon is Weapon:
		var w := current_weapon as Weapon
		w.reload_time = w._base_reload_time * 0.5
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

func refill_all_ammo() -> void:
	for w in weapons:
		if w is Weapon:
			(w as Weapon).refill_ammo()

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
				var w := current_weapon as Weapon
				w.reload_time = w._base_reload_time * 0.5
		"quick_revive":
			has_quick_revive = true
