extends Node

const RATE: int = 22050
const POOL_SIZE: int = 12

var _pool: Array[AudioStreamPlayer] = []
var _fire_light: AudioStreamPlayer
var _fire_smg: AudioStreamPlayer
var _fire_heavy: AudioStreamPlayer
var _streams: Dictionary = {}

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

func _new_player(vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol_db
	add_child(p)
	return p

func play(id: String) -> void:
	if not _streams.has(id):
		return
	var s := _streams[id] as AudioStreamWAV
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.play()
			return
	_pool[0].stream = s
	_pool[0].play()

# ── Sound generation ───────────────────────────────────────────────────

func _gen_all() -> void:
	# Weapons
	_streams["carbine_fire"] = _noise(0.18, 310.0, 0.25, 3.5, 0.90)
	_streams["smg_fire"]     = _noise(0.10, 420.0, 0.20, 4.2, 0.72)
	_streams["rifle_fire"]   = _rifle(0.26, 0.96)
	_streams["melee_hit"]    = _noise(0.14, 140.0, 0.45, 2.5, 0.80)
	_streams["dry_fire"]     = _noise(0.05, 2400.0, 0.04, 8.0, 0.50)
	_streams["reload"]       = _clicks([0.00, 0.30], 0.055, 2200.0, 0.65)

	# Zombies — use _groan for richer multi-harmonic texture at lower volume
	_streams["zombie_growl"]  = _groan(1.10,  75.0,  62.0, 0.30, 0.28)
	_streams["zombie_hurt"]   = _groan(0.30, 165.0, 105.0, 0.48, 0.40)
	_streams["zombie_death"]  = _groan(1.50, 185.0,  44.0, 0.38, 0.44)
	_streams["zombie_attack"] = _groan(0.30, 245.0, 195.0, 0.52, 0.42)

	# Player
	_streams["player_hurt"]   = _noise(0.20, 260.0, 0.38, 2.5, 0.62)
	_streams["player_downed"] = _moan(1.50, 220.0,  55.0, 0.85)
	_streams["player_revive"] = _arp([523.25, 659.26, 783.99], 0.18, 0.55)

	# Power-ups (WaW-inspired note sequences)
	_streams["pu_max_ammo"]   = _arp([392.00, 493.88, 587.33, 783.99], 0.15, 0.65)
	_streams["pu_dbl_pts"]    = _arp([440.00, 554.37, 659.26, 880.00], 0.13, 0.62)
	_streams["pu_insta_kill"] = _arp([523.25, 392.00, 329.63, 659.26], 0.14, 0.62)
	_streams["pu_nuke"]       = _noise(0.90,  55.0, 0.85, 1.0, 0.95)
	_streams["pu_spawn"]      = _arp([880.00, 1108.73, 1318.51], 0.08, 0.45)

	# Purchases / interactions
	_streams["purchase_ok"]   = _arp([392.00, 523.25], 0.10, 0.52)
	_streams["purchase_no"]   = _tone(0.22, 180.0, 155.0, 2.5, 0.62)
	_streams["door_open"]     = _noise(0.40,  75.0, 0.65, 1.3, 0.72)
	_streams["mystery_box"]   = _arp([523.25, 587.33, 659.26, 783.99, 880.00], 0.12, 0.58)
	_streams["perk_jingle"]   = _arp([392.00, 493.88, 587.33, 659.26, 783.99], 0.20, 0.62)

	# Round / game
	_streams["round_start"]    = _arp([261.63, 329.63, 392.00, 523.25],  0.18, 0.65)
	_streams["round_complete"] = _arp([523.25, 659.26, 783.99, 1046.50], 0.20, 0.62)
	_streams["game_over"]      = _arp([392.00, 329.63, 261.63, 196.00],  0.26, 0.65)

	# Hit markers
	_streams["hit_body"] = _noise(0.04, 1800.0, 0.06, 7.0, 0.40)
	_streams["hit_head"] = _noise(0.06, 2400.0, 0.05, 6.0, 0.55)

# ── Synthesis primitives ───────────────────────────────────────────────

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.data     = data
	s.format   = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo   = false
	return s

func _noise(dur: float, tone_hz: float, tone_mix: float, decay: float, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var d := PackedByteArray()
	d.resize(n * 2)
	for i in n:
		var t   := float(i) / float(n)
		var env := pow(1.0 - t, decay)
		var nz  := randf_range(-1.0, 1.0)
		var tn  := sin(TAU * tone_hz * float(i) / RATE)
		var s   := (nz * (1.0 - tone_mix) + tn * tone_mix) * env * vol
		d.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

func _tone(dur: float, hz_a: float, hz_b: float, decay: float, vol: float) -> AudioStreamWAV:
	var n  := int(RATE * dur)
	var d  := PackedByteArray()
	d.resize(n * 2)
	var ph := 0.0
	for i in n:
		var t  := float(i) / float(n)
		var hz := lerpf(hz_a, hz_b, t)
		ph += TAU * hz / RATE
		var s := sin(ph) * pow(1.0 - t, decay) * vol
		d.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

func _moan(dur: float, hz_start: float, hz_end: float, vol: float) -> AudioStreamWAV:
	# Soft-clipped sine + noise — gritty vocal/zombie texture
	var n  := int(RATE * dur)
	var d  := PackedByteArray()
	d.resize(n * 2)
	var ph := 0.0
	for i in n:
		var t   := float(i) / float(n)
		var env := sin(PI * t) * vol
		var hz  := lerpf(hz_start, hz_end, t)
		ph += TAU * hz / RATE
		var raw := sin(ph) * 0.75 + randf_range(-1.0, 1.0) * 0.25
		var s   := tanh(raw * 2.5) * env * 0.5
		d.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

func _groan(dur: float, hz_start: float, hz_end: float, rasp: float, vol: float) -> AudioStreamWAV:
	# Multi-harmonic zombie vocal: fundamental + detuned 2nd + 3rd, with tremolo
	var n      := int(RATE * dur)
	var d      := PackedByteArray()
	d.resize(n * 2)
	var ph1    := 0.0
	var ph2    := 0.0
	var ph3    := 0.0
	var ph_lfo := 0.0
	for i in n:
		var t   := float(i) / float(n)
		# Fast attack (8%), sustain, tail release (25%)
		var env := 1.0
		if t < 0.08:
			env = t / 0.08
		elif t > 0.75:
			env = (1.0 - t) / 0.25
		var hz := lerpf(hz_start, hz_end, t)
		ph1    += TAU * hz         / RATE
		ph2    += TAU * (hz * 2.07) / RATE   # slightly sharp 2nd adds organic roughness
		ph3    += TAU * (hz * 3.0)  / RATE
		ph_lfo += TAU * 3.8         / RATE   # 3.8 Hz breathing tremolo
		var trem := 0.87 + 0.13 * sin(ph_lfo)
		var tone := sin(ph1) * 0.58 + sin(ph2) * 0.28 + sin(ph3) * 0.14
		var raw  := tone * (1.0 - rasp) + randf_range(-1.0, 1.0) * rasp
		var s    := tanh(raw * 2.1) * env * trem * vol
		d.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

func _arp(freqs: Array[float], note_dur: float, vol: float) -> AudioStreamWAV:
	var spn := int(RATE * note_dur)
	var n   := spn * freqs.size()
	var d   := PackedByteArray()
	d.resize(n * 2)
	var ph  := 0.0
	for i in n:
		var ni  := mini(i / spn, freqs.size() - 1)
		var tn  := float(i % spn) / float(spn)
		var env := sin(PI * tn) * vol
		ph += TAU * freqs[ni] / RATE
		var s := sin(ph) * env
		d.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

func _rifle(dur: float, vol: float) -> AudioStreamWAV:
	# Low boom + metallic Garand ping
	var n     := int(RATE * dur)
	var d     := PackedByteArray()
	d.resize(n * 2)
	var ph_lo := 0.0
	var ph_hi := 0.0
	for i in n:
		var t    := float(i) / float(n)
		var e_lo := pow(1.0 - t, 2.5)
		var e_hi := pow(1.0 - t, 5.0) * 0.35
		ph_lo += TAU * 180.0  / RATE
		ph_hi += TAU * 1600.0 / RATE
		var boom := (randf_range(-1.0, 1.0) * 0.65 + sin(ph_lo) * 0.35) * e_lo
		var ping := sin(ph_hi) * e_hi
		var s    := (boom + ping) * vol
		d.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

func _clicks(times: Array[float], click_dur: float, hz: float, vol: float) -> AudioStreamWAV:
	var total := int(RATE * (times[-1] + click_dur + 0.08))
	var d     := PackedByteArray()
	d.resize(total * 2)
	var csamp := int(RATE * click_dur)
	for ct: float in times:
		var start := int(ct * RATE)
		for j in csamp:
			if start + j >= total:
				break
			var t   := float(j) / float(csamp)
			var env := pow(1.0 - t, 6.0)
			var nz  := randf_range(-1.0, 1.0) * 0.9
			var tn  := sin(TAU * hz * float(j) / RATE) * 0.1
			var s   := (nz + tn) * env * vol
			d.encode_s16((start + j) * 2, int(clamp(s, -1.0, 1.0) * 32767))
	return _wav(d)

# ── Signal wiring ──────────────────────────────────────────────────────

func _connect_signals() -> void:
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(func(_a: int, _b: String) -> void: play("reload"))
	EventBus.weapon_dry_fired.connect(func(_a: int) -> void: play("dry_fire"))
	EventBus.player_damaged.connect(func(_a: int, _b: int, _c: int) -> void: play("player_hurt"))
	EventBus.player_downed.connect(func(_a: int) -> void: play("player_downed"))
	EventBus.player_revived.connect(func(_a: int, _b: int) -> void: play("player_revive"))
	EventBus.hit_registered.connect(_on_hit_registered)
	EventBus.door_opened.connect(func(_a: String, _b: int, _c: int) -> void: play("door_open"))
	EventBus.perk_purchased.connect(func(_a: int, _b: String, _c: int) -> void: play("perk_jingle"))
	EventBus.weapon_purchased.connect(func(_a: int, _b: String, _c: int) -> void: play("purchase_ok"))
	EventBus.mystery_box_used.connect(func(_a: int) -> void: play("mystery_box"))
	EventBus.zombie_hurt.connect(func(_a: String) -> void: play("zombie_hurt"))
	EventBus.zombie_died.connect(func(_a: String) -> void: play("zombie_death"))
	EventBus.zombie_idle.connect(func() -> void: play("zombie_growl"))
	EventBus.zombie_attacked.connect(func(_a: Node, _b: Node) -> void: play("zombie_attack"))
	EventBus.purchase_denied.connect(func(_a: int) -> void: play("purchase_no"))
	GameManager.powerup_activated.connect(_on_powerup_activated)
	GameManager.round_started.connect(func(_a: int) -> void: play("round_start"))
	GameManager.round_ended.connect(func(_a: int) -> void: play("round_complete"))
	GameManager.game_over.connect(func() -> void: play("game_over"))

func _on_weapon_fired(_pid: int, wname: String) -> void:
	match wname:
		"Thompson SMG":
			_fire_smg.stream = _streams["smg_fire"] as AudioStreamWAV
			_fire_smg.play()
		"M1 Garand":
			_fire_heavy.stream = _streams["rifle_fire"] as AudioStreamWAV
			_fire_heavy.play()
		_:
			_fire_light.stream = _streams["carbine_fire"] as AudioStreamWAV
			_fire_light.play()

func _on_hit_registered(_pid: int, is_headshot: bool) -> void:
	play("hit_head" if is_headshot else "hit_body")

func _on_powerup_activated(type: String, _dur: float) -> void:
	match type:
		"max_ammo":       play("pu_max_ammo")
		"nuke":           play("pu_nuke")
		"double_points":  play("pu_dbl_pts")
		"insta_kill":     play("pu_insta_kill")
