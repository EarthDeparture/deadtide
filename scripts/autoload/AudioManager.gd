extends Node

const POOL_SIZE: int = 12

var _pool: Array[AudioStreamPlayer] = []
var _fire_light: AudioStreamPlayer
var _fire_smg: AudioStreamPlayer
var _fire_heavy: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _streams: Dictionary = {}
var _zombie_streams: Array[AudioStream] = []

func _ready() -> void:
	_build_pool()
	_gen_all()
	_connect_signals()

# ── Pool ───────────────────────────────────────────────────────────────

func _build_pool() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_fire_light = _new_player(-3.0)
	_fire_smg   = _new_player(-5.0)
	_fire_heavy = _new_player(0.0)
	_ambience = _new_player(-18.0)
	_ambience.stream = load("res://assets/audio/horror_ambience.ogg")
	(_ambience.stream as AudioStreamOggVorbis).loop = true
	_ambience.play()

func _new_player(vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol_db
	add_child(p)
	return p

func play(id: String) -> void:
	if not _streams.has(id):
		return
	var s := _streams[id] as AudioStream
	for p in _pool:
		if not p.playing:
			p.pitch_scale = 1.0
			p.stream = s
			p.play()
			return
	_pool[0].pitch_scale = 1.0
	_pool[0].stream = s
	_pool[0].play()

func _play_zombie(pitch_scale: float) -> void:
	if _zombie_streams.is_empty():
		return
	var s: AudioStream = _zombie_streams[randi() % _zombie_streams.size()]
	for p in _pool:
		if not p.playing:
			p.pitch_scale = pitch_scale
			p.stream = s
			p.play()
			return
	_pool[0].pitch_scale = pitch_scale
	_pool[0].stream = s
	_pool[0].play()

# ── Stream loading ─────────────────────────────────────────────────────

func _gen_all() -> void:
	# Weapons
	_streams["carbine_fire"] = load("res://assets/audio/m1911.wav")
	_streams["smg_fire"]     = load("res://assets/audio/thompson.wav")
	_streams["rifle_fire"]   = load("res://assets/audio/m1_garand.ogg")
	_streams["garand_ping"]  = load("res://assets/audio/m1_garand_ping.wav")
	_streams["melee_hit"]    = load("res://assets/audio/wet_impact.ogg")
	_streams["dry_fire"]     = load("res://assets/audio/dry_fire.wav")
	_streams["reload"]       = load("res://assets/audio/reload.mp3")

	# Zombies — pool of 3 variants, pitch-shifted per event in _play_zombie()
	_zombie_streams = [
		load("res://assets/audio/zombie_01.ogg"),
		load("res://assets/audio/zombie_02.ogg"),
		load("res://assets/audio/zombie_03.wav"),
	]

	# Player
	_streams["player_hurt"]   = load("res://assets/audio/hurt_sound.wav")
	_streams["player_downed"] = load("res://assets/audio/hurt_sound.wav")
	_streams["player_revive"] = load("res://assets/audio/player_revive.wav")

	# Power-ups — single shared file for all power-up pickups
	var pu := load("res://assets/audio/power-up.wav")
	_streams["pu_max_ammo"]   = pu
	_streams["pu_dbl_pts"]    = pu
	_streams["pu_insta_kill"] = pu
	_streams["pu_nuke"]       = pu
	_streams["pu_spawn"]      = pu

	# Purchases / interactions
	_streams["purchase_ok"]    = load("res://assets/audio/purchase.wav")
	_streams["purchase_no"]    = load("res://assets/audio/denied.wav")
	_streams["door_open"]      = load("res://assets/audio/door_open.wav")
	_streams["mystery_box"]    = load("res://assets/audio/mystery_box.ogg")
	_streams["perk_jingle"]    = load("res://assets/audio/purchase.wav")

	# Barricades
	_streams["board_broken"]   = load("res://assets/audio/wood_board_creak.ogg")
	_streams["board_repaired"] = load("res://assets/audio/hammering.wav")

	# Round / game
	_streams["round_start"]    = load("res://assets/audio/round_start.ogg")
	_streams["round_complete"] = load("res://assets/audio/round_complete.ogg")
	_streams["game_over"]      = load("res://assets/audio/game_over.ogg")

	# Hit markers
	_streams["hit_body"] = load("res://assets/audio/wet_impact.ogg")
	_streams["hit_head"] = load("res://assets/audio/wet_impact.ogg")

# ── Signal wiring ──────────────────────────────────────────────────────

func _connect_signals() -> void:
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.weapon_dry_fired.connect(func(_a: int) -> void: play("dry_fire"))
	EventBus.player_damaged.connect(func(_a: int, _b: int, _c: int) -> void: play("player_hurt"))
	EventBus.player_downed.connect(func(_a: int) -> void: play("player_downed"))
	EventBus.player_revived.connect(func(_a: int, _b: int) -> void: play("player_revive"))
	EventBus.hit_registered.connect(_on_hit_registered)
	EventBus.door_opened.connect(func(_a: String, _b: int, _c: int) -> void: play("door_open"))
	EventBus.perk_purchased.connect(func(_a: int, _b: String, _c: int) -> void: play("perk_jingle"))
	EventBus.weapon_purchased.connect(func(_a: int, _b: String, _c: int) -> void: play("purchase_ok"))
	EventBus.mystery_box_used.connect(func(_a: int) -> void: play("mystery_box"))
	EventBus.board_broken.connect(func() -> void: play("board_broken"))
	EventBus.window_repaired.connect(func(_a: String, _b: int) -> void: play("board_repaired"))
	EventBus.zombie_hurt.connect(func(_a: String) -> void: _play_zombie(1.4))
	EventBus.zombie_died.connect(func(_a: String) -> void: _play_zombie(0.85))
	EventBus.zombie_idle.connect(func() -> void: _play_zombie(1.0))
	EventBus.zombie_attacked.connect(func(_a: Node, _b: Node) -> void: _play_zombie(1.6))
	EventBus.purchase_denied.connect(func(_a: int) -> void: play("purchase_no"))
	GameManager.powerup_activated.connect(_on_powerup_activated)
	GameManager.round_started.connect(func(_a: int) -> void: play("round_start"))
	GameManager.round_ended.connect(func(_a: int) -> void: play("round_complete"))
	GameManager.game_over.connect(func() -> void: play("game_over"))

func _on_weapon_reloaded(_pid: int, wname: String) -> void:
	play("reload")
	if wname == "M1 Garand":
		await get_tree().create_timer(0.6).timeout
		play("garand_ping")

func _on_weapon_fired(_pid: int, wname: String) -> void:
	match wname:
		"Thompson SMG":
			_fire_smg.stream = _streams["smg_fire"] as AudioStream
			_fire_smg.play()
		"M1 Garand":
			_fire_heavy.stream = _streams["rifle_fire"] as AudioStream
			_fire_heavy.play()
		_:
			_fire_light.stream = _streams["carbine_fire"] as AudioStream
			_fire_light.play()

func _on_hit_registered(_pid: int, is_headshot: bool) -> void:
	play("hit_head" if is_headshot else "hit_body")

func _on_powerup_activated(type: String, _dur: float) -> void:
	match type:
		"max_ammo":      play("pu_max_ammo")
		"nuke":          play("pu_nuke")
		"double_points": play("pu_dbl_pts")
		"insta_kill":    play("pu_insta_kill")
