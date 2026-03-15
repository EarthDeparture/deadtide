extends Node

# Player events
signal player_damaged(player_id: int, damage: int, current_health: int)
signal player_healed(player_id: int, heal_amount: int, current_health: int)
signal player_downed(player_id: int)
signal player_revived(player_id: int, reviver_id: int)
signal player_revive_tick(player_id: int, time_remaining: float)

# Weapon events
signal hit_registered(player_id: int, is_headshot: bool)
signal headshot_hit(player_id: int)
signal weapon_fired(player_id: int, weapon_name: String)
signal weapon_reloaded(player_id: int, weapon_name: String)
signal weapon_dry_fired(player_id: int)
signal weapon_purchased(player_id: int, weapon_name: String, cost: int)
signal ammo_picked_up(player_id: int, weapon_name: String, amount: int)

# Map events
signal door_opened(door_id: String, player_id: int, cost: int)
signal perk_purchased(player_id: int, perk_name: String, cost: int)
signal power_activated(player_id: int)
signal purchase_denied(player_id: int)
signal mystery_box_used(player_id: int)

# Zombie events
signal zombie_spawned(zombie: Node)
signal zombie_attacked(zombie: Node, target: Node)
signal zombie_hurt(damage_type: String)
signal zombie_died(damage_type: String)
signal zombie_idle()
signal window_repaired(window_id: String, points_awarded: int)

# Game events
signal game_won(score: int)
signal game_lost(reason: String)

func emit_player_damaged(player_id: int, damage: int, current_health: int) -> void:
	player_damaged.emit(player_id, damage, current_health)

func emit_player_healed(player_id: int, heal_amount: int, current_health: int) -> void:
	player_healed.emit(player_id, heal_amount, current_health)

func emit_player_downed(player_id: int) -> void:
	player_downed.emit(player_id)

func emit_player_revived(player_id: int, reviver_id: int) -> void:
	player_revived.emit(player_id, reviver_id)

func emit_hit_registered(player_id: int, is_headshot: bool) -> void:
	hit_registered.emit(player_id, is_headshot)

func emit_headshot_hit(player_id: int) -> void:
	headshot_hit.emit(player_id)

func emit_weapon_fired(player_id: int, weapon_name: String) -> void:
	weapon_fired.emit(player_id, weapon_name)

func emit_weapon_reloaded(player_id: int, weapon_name: String) -> void:
	weapon_reloaded.emit(player_id, weapon_name)

func emit_weapon_dry_fired(player_id: int) -> void:
	weapon_dry_fired.emit(player_id)

func emit_weapon_purchased(player_id: int, weapon_name: String, cost: int) -> void:
	weapon_purchased.emit(player_id, weapon_name, cost)

func emit_door_opened(door_id: String, player_id: int, cost: int) -> void:
	door_opened.emit(door_id, player_id, cost)

func emit_perk_purchased(player_id: int, perk_name: String, cost: int) -> void:
	perk_purchased.emit(player_id, perk_name, cost)

func emit_purchase_denied(player_id: int) -> void:
	purchase_denied.emit(player_id)

func emit_mystery_box_used(player_id: int) -> void:
	mystery_box_used.emit(player_id)

func emit_zombie_hurt(damage_type: String) -> void:
	zombie_hurt.emit(damage_type)

func emit_zombie_died(damage_type: String) -> void:
	zombie_died.emit(damage_type)

func emit_zombie_idle() -> void:
	zombie_idle.emit()

func emit_window_repaired(window_id: String, points: int) -> void:
	window_repaired.emit(window_id, points)
