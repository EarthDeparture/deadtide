# Dead Tide

Wave-based zombie survival game inspired by classic Call of Duty zombies mode.

## Overview

Dead Tide is a cooperative zombie survival game where players must survive endless waves of undead enemies. Inspired by the iconic Nazi Zombies mode from Call of Duty: World at War, Dead Tide features:

- Wave-based progression with increasing difficulty
- Points-based economy system
- Weapon purchasing (wall buys, mystery box)
- Perk system
- Map progression (locked doors, areas)
- 4-player cooperative gameplay

## Tech Stack

- **Engine:** Godot 4.6.1
- **Language:** GDScript
- **Rendering:** Forward+ (for 3D)
- **Target Platforms:** macOS, Windows, Linux, Web

## Project Structure

```
res:///
├── scenes/
│   ├── main/          # Main game scene
│   ├── core/          # Player, camera, etc.
│   ├── enemies/       # Zombie scenes
│   ├── maps/          # Map scenes
│   ├── ui/            # HUD, menus
│   └── weapons/       # Weapon scenes
├── scripts/
│   ├── autoload/      # Singleton managers
│   ├── player/        # Player controller
│   ├── enemies/       # Zombie AI
│   ├── weapons/       # Weapon logic
│   └── maps/          # Map logic
└── assets/
    ├── models/
    ├── textures/
    ├── audio/
    └── materials/
```

## Autoload Managers

### GameManager
Manages game state, rounds, and player data.

### ZombieManager
Handles zombie spawning, tracking, and wave logic.

### EventBus
Global event system for cross-component communication.

## Controls

| Action | Key |
|--------|-----|
| Move Forward | W |
| Move Backward | S |
| Move Left | A |
| Move Right | D |
| Jump | Space |
| Sprint | Shift |
| Shoot | Left Click |
| Reload | R |
| Interact | F |

## Getting Started

1. Clone the repository
2. Open in Godot 4.6.1
3. Run the project (F5 or F6)

## Development Roadmap

### MVP (v0.1)
- [x] Core game loop structure
- [ ] Player FPS controller
- [ ] Basic zombie AI
- [ ] Weapon system
- [ ] Wave spawning logic
- [ ] Points system
- [ ] Single room prototype map

### v0.2
- [ ] Multiplayer support
- [ ] Perk system (Jugger-Nog)
- [ ] Wall buy weapons
- [ ] Door unlocking system
- [ ] Map expansion (multiple rooms)

### v0.3
- [ ] Mystery box
- [ ] Pack-a-Punch machine
- [ ] Additional perks
- [ ] Power system
- [ ] Traps

### v1.0
- [ ] Full multiplayer
- [ ] Complete perk set (6 perks)
- [ ] Multiple maps
- [ ] Easter eggs
- [ ] Boss rounds

## Contributing

This is a collaborative project between Troy and victorystyle.

## License

TBD
