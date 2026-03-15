extends Node

# Player events
signal player_damaged(player_id: int, damage: int, current_health: int)
signal player_healed(player_id: int, heal_amount: int, current_health: int)
signal player_downed(player_id: int)
signal player_revived(player_id: int, reviver_id: int)

# Weapon events
signal weapon_fired(player_id: int, weapon_name: String)
signal weapon_reloaded(player_id: int, weapon_name: String)
signal weapon_purchased(player_id: int, weapon_name: String, cost: int)
signal ammo_picked_up(player_id: int, weapon_name: String, amount: int)

# Map events
signal door_opened(door_id: String, player_id: int, cost: int)
signal perk_purchased(player_id: int, perk_name: String, cost: int)
signal power_activated(player_id: int)

# Zombie events
signal zombie_spawned(zombie: Node)
signal zombie_attacked(zombie: Node, target: Node)
signal window_repaired(window_id: String, points_awarded: int)

# Game events
signal game_won(score: int)
signal game_lost(reason: String)

func emit_player_damaged(player_id: int, damage: int, current_health: int):
    player_damaged.emit(player_id, damage, current_health)

func emit_player_healed(player_id: int, heal_amount: int, current_health: int):
    player_healed.emit(player_id, heal_amount, current_health)

func emit_player_downed(player_id: int):
    player_downed.emit(player_id)

func emit_player_revived(player_id: int, reviver_id: int):
    player_revived.emit(player_id, reviver_id)

func emit_weapon_fired(player_id: int, weapon_name: String):
    weapon_fired.emit(player_id, weapon_name)

func emit_weapon_reloaded(player_id: int, weapon_name: String):
    weapon_reloaded.emit(player_id, weapon_name)

func emit_weapon_purchased(player_id: int, weapon_name: String, cost: int):
    weapon_purchased.emit(player_id, weapon_name, cost)

func emit_door_opened(door_id: String, player_id: int, cost: int):
    door_opened.emit(door_id, player_id, cost)

func emit_perk_purchased(player_id: int, perk_name: String, cost: int):
    perk_purchased.emit(player_id, perk_name, cost)
