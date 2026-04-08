# AGENTS.md — typeticker

## Project
Godot 4.2 project using GDScript and the GL Compatibility renderer.

## Structure
```
project.godot       # project config — edit via Godot editor, not by hand
scenes/Main.tscn    # entry point scene (set in project.godot run/main_scene)
scripts/Main.gd     # script attached to Main scene root node
assets/             # sprites, sounds, fonts (currently empty)
```

## Key facts
- **Godot version:** 4.2 (config_version=5)
- **Renderer:** GL Compatibility (not Forward+/Mobile) — keep new nodes compatible with this renderer
- **Entry scene:** `res://scenes/Main.tscn`
- **Script language:** GDScript only — no C#
- **Scene/script convention:** scenes live in `scenes/`, scripts in `scripts/`, one script per scene file

## Editing rules
- `.tscn` files use Godot's text scene format — prefer editing them through the Godot editor to avoid malformed UIDs or broken resource references
- `project.godot` should only be changed via the Godot editor UI; hand-edits can silently break the project
- `res://` paths are relative to the project root, not the filesystem

## Running the project
Open in Godot 4 editor: **Project Manager → Import → select `project.godot`**
Run: **F5** (or the play button) — no CLI build step exists for GDScript projects

## Tooling
There is no lint, format, typecheck, test runner, or CI configured. Static analysis is editor-only (Godot's built-in). Do not look for `gdlint`, `gdformat`, GUT, or any Makefile/taskfile — none exist.

## Git
- Branch: `master`
- `.godot/` cache directory and `*.translation` files are gitignored — do not commit them
- `AGENTS.md` should be committed alongside code changes
