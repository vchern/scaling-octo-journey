# scaling-octo-journey

A 2D MapleStory-inspired platformer-RPG in Godot 4.x + GDScript.

## Run

1. Install Godot 4.6+ from [godotengine.org](https://godotengine.org/) (scaffolded against 4.6.3 stable).
2. Open `project.godot` in the Godot editor, or run `godot --path .` from this directory.
3. Press **F5** to run.

You should see a green floor and a blue rectangle (the player). Hold **Left/A** or **Right/D** to move horizontally.

## Controls (defaults)

| Action  | Classic    | Modern |
|---------|------------|--------|
| Move    | Arrow keys | WASD   |
| Jump    | Space      | Space  |
| Attack  | Z          | J      |
| Skill 1 | X          | K      |
| Skill 2 | C          | L      |

Most actions aren't implemented yet — see roadmap.

## Roadmap

- **Phase 0** *(current)*: scaffolding + input pipeline
- Phase 1: platformer movement feel (gravity, variable jump, one-way platforms, camera)
- Phase 2: ropes/ladders + TileMap-based maps
- Phase 3 (= v0.1): combat — one mob, one map, kill loop
- Phase 4+: real art, HUD/EXP, inventory, classes, quests, save/load, networking
