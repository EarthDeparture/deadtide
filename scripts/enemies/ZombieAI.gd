class_name ZombieAI
extends CharacterBody3D

signal killed(zombie: Node, damage_type: String, player_id: int)

const RUN_SPEED: float = 4.0
const ATTACK_DAMAGE: int = 25
const ATTACK_COOLDOWN: float = 1.5

var health: int = 100
var max_health: int = 100
var target: Node3D = null
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var round_multiplier: float = 1.0

@onready var attack_area: Area3D = $AttackArea

func _ready():
	attack_area.body_entered.connect(_on_body_entered_attack_area)

func set_round_difficulty(round_number: int):
	round_multiplier = 1.0 + (round_number * 0.1)
	health = int(max_health * round_multiplier)

func set_target(player: Node3D):
	target = player

func _physics_process(delta: float):
	if target == null or not is_instance_valid(target):
		return
	var target_flat := Vector3(target.global_position.x, global_position.y, target.global_position.z)
	look_at(target_flat, Vector3.UP)
	var direction: Vector3 = (target.global_position - global_position).normalized()
	var speed: float = RUN_SPEED * round_multiplier
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	if is_attacking:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			is_attacking = false

func _on_body_entered_attack_area(body: Node):
	if body.has_method("take_damage") and not is_attacking:
		_attack(body)

func _attack(player):
	is_attacking = true
	attack_cooldown_timer = ATTACK_COOLDOWN
	var damage: int = int(ATTACK_DAMAGE * round_multiplier)
	player.take_damage(damage)

func take_damage(amount: int, damage_type: String, attacker_id: int):
	health -= amount
	if health <= 0:
		die(damage_type, attacker_id)

func die(damage_type: String, attacker_id: int):
	killed.emit(self, damage_type, attacker_id)
	queue_free()
