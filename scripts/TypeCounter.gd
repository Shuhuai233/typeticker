extends Node2D

var count: int = 0
var flash_timer: float = 0.0
const FLASH_DURATION := 0.08

# Colors
const COLOR_BG       := Color(0.10, 0.10, 0.12, 0.88)
const COLOR_BG_FLASH := Color(0.22, 0.20, 0.32, 0.92)
const COLOR_TEXT     := Color(0.95, 0.92, 0.88)
const COLOR_LABEL    := Color(0.55, 0.52, 0.65)
const COLOR_ACCENT   := Color(0.95, 0.80, 0.35)
const COLOR_BORDER   := Color(0.30, 0.28, 0.40)

var window_drag := false
var drag_offset := Vector2i.ZERO

func _ready() -> void:
	# Always on top, borderless, small window
	get_window().always_on_top = true
	get_window().borderless = true
	get_window().transparent = true
	get_window().size = Vector2i(200, 90)
	get_window().position = Vector2i(40, 40)

func _input(event: InputEvent) -> void:
	# Count any key press
	if event is InputEventKey and event.pressed and not event.echo:
		count += 1
		flash_timer = FLASH_DURATION
		queue_redraw()

	# Drag window by mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				window_drag = true
				drag_offset = get_window().position - Vector2i(DisplayServer.mouse_get_position())
			else:
				window_drag = false

	if event is InputEventMouseMotion and window_drag:
		get_window().position = Vector2i(DisplayServer.mouse_get_position()) + drag_offset

	# Right-click to reset
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			count = 0
			queue_redraw()

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		queue_redraw()

func _draw() -> void:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	# Background
	var bg := COLOR_BG_FLASH if flash_timer > 0.0 else COLOR_BG
	draw_rect(Rect2(0, 0, w, h), bg, true, -1.0, true)

	# Border
	draw_rect(Rect2(1, 1, w - 2, h - 2), COLOR_BORDER, false, 1.5, true)

	# "KEYSTROKES" label
	draw_string(ThemeDB.fallback_font, Vector2(w / 2.0, 20),
		"KEYSTROKES", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, COLOR_LABEL)

	# Count number
	var col := COLOR_ACCENT if flash_timer > 0.0 else COLOR_TEXT
	draw_string(ThemeDB.fallback_font, Vector2(w / 2.0, 62),
		str(count), HORIZONTAL_ALIGNMENT_CENTER, -1, 48, col)

	# Hint
	draw_string(ThemeDB.fallback_font, Vector2(w / 2.0, h - 6),
		"right-click to reset", HORIZONTAL_ALIGNMENT_CENTER, -1, 10,
		Color(COLOR_LABEL, 0.5))
