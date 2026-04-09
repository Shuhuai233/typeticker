# Desktop Pet - Whip Edition

A meme-inspired always-on-top desktop overlay that reacts to every keystroke, mouse click, and controller input — no matter what window is focused.

Built with **Godot 4** using pure GDScript drawing (no external image assets).

---

## Vision

Most input trackers are boring counters. This one is a **living desktop companion** that suffers alongside you as you type, click, and game. Inspired by Bongo Cat but with a darker, meme-driven aesthetic aimed at developers and streamers who want something absurd floating on their screen.

The goal is a **fully self-contained, zero-dependency overlay** — extract and run, no install needed. Skinnable, configurable, and always watching.

---

## Features

- **Always on top** — floats above all windows, never gets buried
- **Global input detection** — counts keyboard, mouse, and controller input even when the app is unfocused (via `global_input_hook.exe`)
- **5 skins** — switch on the fly via right-click menu
- **Configurable** — scale (75/100/150%), opacity (40/70/100%), all saved automatically
- **Counter persists** between sessions
- **Ctrl+R** to reset counter
- **Drag** anywhere to reposition, position saved on exit
- **Right-click menu** for all options

---

## Skins

| Skin | Description |
|------|-------------|
| **AI Master + Wojak** | An Adobe Ai icon boss whips a kneeling crying Wojak on every input. Text: "折磨自己吧 / 工具人" |
| **Tired Programmer** | A dev with eye bags slams the keyboard, coffee steaming nearby |
| **Anime Girl** | Chibi character waves and gets excited with star eyes on input |
| **Spooky Skeleton** | Rattling bones and glowing eyes, floating bonus bones on input |
| **Robot** | Mechanical servo arms, LED indicators, screen bar chart, sparks on input |

---

## Usage

1. Extract the zip
2. Run `desktoppet-v0.5.0.exe`
3. `global_input_hook.exe` must be in the same folder for global input
4. Right-click to open settings menu
5. Drag to move, Ctrl+R to reset

Shows `[global]` badge when hook is active, `[local]` if hook is missing (only counts input when window is focused).

---

## Roadmap

- [ ] More skins (Bongo Cat original, Among Us, etc.)
- [ ] Custom text labels
- [ ] Sound effects on input
- [ ] Tray icon / minimize to tray
- [ ] Per-key tracking (show which keys are pressed most)
- [ ] Streaming overlay mode (OBS browser source compatible)
- [ ] Config editor UI (no JSON editing needed)

---

## Building from source

Requires **Godot 4.2+**.

```
# Open project
godot-4 --editor project.godot

# Headless export (requires export templates)
godot-4 --headless --export-release "Windows Desktop" build/desktoppet-v0.5.0.exe --path .

# Build global input hook (requires MinGW)
x86_64-w64-mingw32-g++ -shared -o build/global_input_hook.exe \
    extensions/global_input/src/global_input_hook.cpp \
    -std=c++17 -O2 -lxinput -luser32 -lkernel32 -mwindows
```

---

## Tech

- **Engine:** Godot 4.2 (GDScript, GL Compatibility renderer)
- **Drawing:** All characters drawn via `draw_*` canvas calls — no sprites
- **Global input:** Windows low-level keyboard/mouse hooks via `SetWindowsHookEx` + XInput for controllers
- **IPC:** Hook process writes count to temp file, Godot polls every 50ms
- **Config:** JSON file saved next to executable

---

*Built with OpenCode*
