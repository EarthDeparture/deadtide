class_name WindowBarricade
extends Node3D

const BOARD_COUNT: int = 6
const BOARD_REPAIR_POINTS: int = 10
const BOARD_REPAIR_TIME: float = 1.5   # seconds per board (Speed Cola halves this)

var boards: Array[bool] = []
var zombie_at_window: ZombieAI = null
var is_active: bool = true
var _window_id: String = ""

var _nearby_player: PlayerController = null
var _repair_timer: float = 0.0

func _ready() -> void:
	add_to_group("barricades")
	_window_id = name
	for i in range(BOARD_COUNT):
		boards.append(true)
	_update_board_visuals()
	$RepairArea.body_entered.connect(_on_repair_body_entered)
	$RepairArea.body_exited.connect(_on_repair_body_exited)

func _process(delta: float) -> void:
	if _nearby_player == null or not is_instance_valid(_nearby_player):
		_repair_timer = 0.0
		return
	if get_boards_intact() == BOARD_COUNT:
		_repair_timer = 0.0
		return
	if Input.is_action_pressed("interact"):
		_repair_timer += delta
		var threshold: float = BOARD_REPAIR_TIME * 0.5 if _nearby_player.perks.has("speed_cola") else BOARD_REPAIR_TIME
		if _repair_timer >= threshold:
			_repair_timer = 0.0
			_repair_one_board(_nearby_player)
	else:
		_repair_timer = 0.0

func _repair_one_board(player: PlayerController) -> void:
	for i in range(boards.size()):
		if not boards[i]:
			boards[i] = true
			_update_board_visuals()
			GameManager.add_player_points(player.player_id, BOARD_REPAIR_POINTS)
			EventBus.emit_window_repaired(_window_id, BOARD_REPAIR_POINTS)
			return

func _on_repair_body_entered(body: Node) -> void:
	if body is PlayerController:
		_nearby_player = body as PlayerController

func _on_repair_body_exited(body: Node) -> void:
	if body == _nearby_player:
		_nearby_player = null
		_repair_timer = 0.0

# Called by PlayerController when F is pressed — no-op since repair uses hold detection
func interact(_player: PlayerController) -> void:
	pass

func get_prompt() -> String:
	var intact: int = get_boards_intact()
	if intact < BOARD_COUNT:
		return "Hold F: Repair Window [%d/%d]" % [intact, BOARD_COUNT]
	return ""

func get_boards_intact() -> int:
	var count: int = 0
	for b in boards:
		if b:
			count += 1
	return count

func break_next_board() -> bool:
	for i in range(boards.size()):
		if boards[i]:
			boards[i] = false
			_update_board_visuals()
			return get_boards_intact() > 0
	return false

func is_passable() -> bool:
	return get_boards_intact() == 0

func get_exterior_spawn_position() -> Vector3:
	var marker := get_node_or_null("ExteriorSpawnMarker") as Node3D
	if marker != null:
		return marker.global_position
	return global_position

func _update_board_visuals() -> void:
	var boards_node := get_node_or_null("Boards")
	if boards_node == null:
		return
	for i in range(BOARD_COUNT):
		var board := boards_node.get_node_or_null("Board%d" % i) as Node3D
		if board != null:
			board.visible = boards[i]
