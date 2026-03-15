class_name ZombieAI
extends CharacterBody3D

signal killed(zombie: Node, damage_type: String, player_id: int)
signal hit(zombie: Node, damage_type: String, attacker_id: int)

enum State { APPROACHING, WAITING, BREAKING, CLIMBING, CHASING }

const WALK_SPEED: float = 1.4
const RUN_SPEED: float = 2.8
const SPRINT_SPEED: float = 4.5
const PROXIMITY_SPRINT_RANGE: float = 4.0
const ATTACK_DAMAGE: int = 50
const ATTACK_COOLDOWN: float = 1.5
const BASE_COLOR := Color(0.28, 0.22, 0.16, 1)
const BASE_HEAD_COLOR := Color(0.32, 0.25, 0.18, 1)
const HIT_COLOR := Color(1.0, 0.1, 0.1, 1)
const BOARD_BREAK_INTERVAL: float = 1.5
const BOARD_BREAK_RANGE: float = 1.2
const CLIMB_TIME: float = 1.0

var health: int = 100
var max_health: int = 100
var target: Node3D = null
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var round_multiplier: float = 1.0
var _base_speed: float = WALK_SPEED
var _round_number: int = 1
var _mat: StandardMaterial3D = null
var _head_mat: StandardMaterial3D = null
var _idle_timer: float = 0.0

var state: State = State.CHASING
var target_window: WindowBarricade = null
var _break_timer: float = 0.0
var _climb_timer: float = 0.0

@onready var attack_area: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var head_mesh: MeshInstance3D = $HeadMesh

func _ready():
	attack_area.body_entered.connect(_on_body_entered_attack_area)
	_mat = mesh_instance.get_active_material(0).duplicate() as StandardMaterial3D
	mesh_instance.set_surface_override_material(0, _mat)
	_head_mat = head_mesh.get_active_material(0).duplicate() as StandardMaterial3D
	head_mesh.set_surface_override_material(0, _head_mat)
	_idle_timer = randf_range(3.0, 8.0)

func set_round_difficulty(round_number: int):
	_round_number = round_number
	round_multiplier = 1.0 + (round_number * 0.1)
	# WaW-accurate health formula:
	# Rounds 1-9: 150 + 100*(round-1)
	# Round 10+:  950 * 1.1^(round-9)
	if round_number <= 1:
		health = 150
	elif round_number <= 9:
		health = 150 + 100 * (round_number - 1)
	else:
		health = int(950.0 * pow(1.1, round_number - 9))
	max_health = health

	if round_number >= 13:
		_base_speed = SPRINT_SPEED
	elif round_number >= 7:
		_base_speed = RUN_SPEED
	elif round_number == 6:
		_base_speed = (WALK_SPEED + RUN_SPEED) * 0.5
	else:
		_base_speed = WALK_SPEED

	_base_speed *= randf_range(0.9, 1.1)

func set_target(player: Node3D):
	target = player

func set_target_window(window: WindowBarricade) -> void:
	target_window = window
	if window != null:
		window.zombie_at_window = self
	state = State.APPROACHING

func _physics_process(delta: float):
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		EventBus.emit_zombie_idle()
		_idle_timer = randf_range(4.0, 9.0)

	if is_attacking:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			is_attacking = false

	if target == null or not is_instance_valid(target):
		return

	match state:
		State.APPROACHING:
			_state_approaching(delta)
		State.WAITING:
			_state_waiting(delta)
		State.BREAKING:
			_state_breaking(delta)
		State.CLIMBING:
			_state_climbing(delta)
		State.CHASING:
			_state_chasing(delta)

func _state_approaching(delta: float) -> void:
	if target_window == null or not is_instance_valid(target_window):
		state = State.CHASING
		return
	if target_window.is_passable():
		target_window = null
		state = State.CHASING
		return
	var tw_pos := target_window.global_position
	var dx: float = tw_pos.x - global_position.x
	var dz: float = tw_pos.z - global_position.z
	var flat_dist: float = sqrt(dx * dx + dz * dz)
	if flat_dist < BOARD_BREAK_RANGE:
		if target_window.zombie_at_window == null or target_window.zombie_at_window == self:
			target_window.zombie_at_window = self
			state = State.BREAKING
			_break_timer = BOARD_BREAK_INTERVAL  # initial grab delay matches pull delay
		else:
			state = State.WAITING
		return
	var look_pos := Vector3(tw_pos.x, global_position.y, tw_pos.z)
	if look_pos.distance_to(global_position) > 0.01:
		look_at(look_pos, Vector3.UP)
	var dir := Vector3(dx, 0, dz).normalized()
	velocity.x = dir.x * _base_speed
	velocity.z = dir.z * _base_speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

func _state_waiting(delta: float) -> void:
	if target_window == null or not is_instance_valid(target_window):
		state = State.CHASING
		return
	if target_window.is_passable():
		target_window = null
		state = State.CHASING
		return
	# Stand still near the window until the active zombie finishes
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	# Take over when the window becomes free
	if target_window.zombie_at_window == null:
		target_window.zombie_at_window = self
		state = State.BREAKING
		_break_timer = BOARD_BREAK_INTERVAL

func _state_breaking(delta: float) -> void:
	if target_window == null or not is_instance_valid(target_window):
		state = State.CHASING
		return
	var tw_pos := target_window.global_position
	var look_pos := Vector3(tw_pos.x, global_position.y, tw_pos.z)
	if look_pos.distance_to(global_position) > 0.01:
		look_at(look_pos, Vector3.UP)
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	_break_timer -= delta
	if _break_timer <= 0.0:
		var boards_remain: bool = target_window.break_next_board()
		if boards_remain:
			_break_timer = BOARD_BREAK_INTERVAL
		else:
			if target_window.zombie_at_window == self:
				target_window.zombie_at_window = null
			state = State.CLIMBING
			_climb_timer = CLIMB_TIME

func _state_climbing(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	_climb_timer -= delta
	if _climb_timer <= 0.0:
		target_window = null
		state = State.CHASING

func _state_chasing(delta: float) -> void:
	var target_flat := Vector3(target.global_position.x, global_position.y, target.global_position.z)
	look_at(target_flat, Vector3.UP)
	var direction: Vector3 = (target.global_position - global_position).normalized()
	var speed: float = _base_speed
	if _round_number >= 10:
		if global_position.distance_to(target.global_position) < PROXIMITY_SPRINT_RANGE:
			speed = SPRINT_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

func _on_body_entered_attack_area(body: Node):
	if body.has_method("take_damage") and not is_attacking:
		_attack(body)

func _attack(player):
	is_attacking = true
	attack_cooldown_timer = ATTACK_COOLDOWN
	# WaW-accurate: 50 dmg R1-5 (2-hit down), 100 dmg R6+ (1-hit down without Juggernog)
	var damage: int = 100 if _round_number >= 6 else ATTACK_DAMAGE
	player.take_damage(damage)
	EventBus.zombie_attacked.emit(self, player)

func take_damage(amount: int, damage_type: String, attacker_id: int):
	health -= amount
	_flash_hit()
	if health <= 0:
		die(damage_type, attacker_id)
	else:
		hit.emit(self, damage_type, attacker_id)
		EventBus.emit_zombie_hurt(damage_type)

func _flash_hit() -> void:
	if _mat == null:
		return
	_mat.albedo_color = HIT_COLOR
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mat, "albedo_color", BASE_COLOR, 0.2)
	if _head_mat:
		_head_mat.albedo_color = HIT_COLOR
		tween.tween_property(_head_mat, "albedo_color", BASE_HEAD_COLOR, 0.2)

func die(damage_type: String, attacker_id: int):
	if target_window != null and is_instance_valid(target_window):
		if target_window.zombie_at_window == self:
			target_window.zombie_at_window = null
	EventBus.emit_zombie_died(damage_type)
	killed.emit(self, damage_type, attacker_id)
	queue_free()
