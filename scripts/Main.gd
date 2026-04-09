extends Node2D

# --- State ---
var left_paw_down := false
var right_paw_down := false
var left_paw_timer := 0.0
var right_paw_timer := 0.0
const PAW_TAP_DURATION := 0.12

var blink_timer := 0.0
var blink_duration := 0.0
var is_blinking := false

var last_key := ""
var key_display_timer := 0.0
const KEY_DISPLAY_DURATION := 0.6

# Left-side keys (left paw)
var LEFT_KEYS = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T,
				   KEY_A, KEY_S, KEY_D, KEY_F, KEY_G,
				   KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B,
				   KEY_1, KEY_2, KEY_3, KEY_4, KEY_5,
				   KEY_TAB, KEY_CAPSLOCK, KEY_SHIFT, KEY_CTRL,
				   KEY_ESCAPE]

# Right-side keys (right paw)
var RIGHT_KEYS = [KEY_Y, KEY_U, KEY_I, KEY_O, KEY_P,
					KEY_H, KEY_J, KEY_K, KEY_L,
					KEY_N, KEY_M, KEY_COMMA, KEY_PERIOD, KEY_SLASH,
					KEY_6, KEY_7, KEY_8, KEY_9, KEY_0,
					KEY_MINUS, KEY_EQUAL, KEY_BACKSPACE,
					KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_BACKSLASH,
					KEY_SEMICOLON, KEY_APOSTROPHE, KEY_ENTER,
					KEY_SPACE, KEY_RIGHT, KEY_LEFT, KEY_UP, KEY_DOWN]

# Colors
const COLOR_BG       := Color(0.18, 0.16, 0.22)
const COLOR_CAT_BODY := Color(0.85, 0.75, 0.65)
const COLOR_CAT_DARK := Color(0.55, 0.45, 0.38)
const COLOR_PAW      := Color(0.85, 0.75, 0.65)
const COLOR_PAW_PAD  := Color(0.90, 0.65, 0.68)
const COLOR_EYE      := Color(0.15, 0.55, 0.35)
const COLOR_PUPIL    := Color(0.05, 0.05, 0.08)
const COLOR_NOSE     := Color(0.88, 0.50, 0.55)
const COLOR_KBD_BG   := Color(0.22, 0.20, 0.28)
const COLOR_KBD_KEY  := Color(0.30, 0.28, 0.36)
const COLOR_KBD_LIT  := Color(0.95, 0.80, 0.35)
const COLOR_TEXT     := Color(0.95, 0.92, 0.88)
const COLOR_OUTLINE  := Color(0.12, 0.10, 0.15)

var screen_center := Vector2.ZERO

func _ready() -> void:
	screen_center = get_viewport_rect().size / 2.0
	_reset_blink()

func _reset_blink() -> void:
	blink_timer = randf_range(2.0, 5.0)
	blink_duration = 0.0
	is_blinking = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.keycode
		if kc in LEFT_KEYS:
			left_paw_down = true
			left_paw_timer = PAW_TAP_DURATION
		elif kc in RIGHT_KEYS:
			right_paw_down = true
			right_paw_timer = PAW_TAP_DURATION
		else:
			# Space / any other key taps both
			left_paw_down = true
			right_paw_down = true
			left_paw_timer = PAW_TAP_DURATION
			right_paw_timer = PAW_TAP_DURATION

		last_key = OS.get_keycode_string(kc)
		key_display_timer = KEY_DISPLAY_DURATION
		queue_redraw()

func _process(delta: float) -> void:
	var changed := false

	if left_paw_timer > 0.0:
		left_paw_timer -= delta
		if left_paw_timer <= 0.0:
			left_paw_down = false
		changed = true

	if right_paw_timer > 0.0:
		right_paw_timer -= delta
		if right_paw_timer <= 0.0:
			right_paw_down = false
		changed = true

	if key_display_timer > 0.0:
		key_display_timer -= delta
		changed = true

	# Blink logic
	if is_blinking:
		blink_duration -= delta
		if blink_duration <= 0.0:
			_reset_blink()
		changed = true
	else:
		blink_timer -= delta
		if blink_timer <= 0.0:
			is_blinking = true
			blink_duration = 0.10
		changed = true

	if changed:
		queue_redraw()

func _draw() -> void:
	var s := screen_center
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	# Background
	draw_rect(Rect2(0, 0, w, h), COLOR_BG)

	# --- Keyboard ---
	_draw_keyboard(s, w, h)

	# --- Cat body ---
	_draw_cat(s)

	# --- Paws ---
	_draw_paw(s + Vector2(-130, 90), left_paw_down, true)
	_draw_paw(s + Vector2(130, 90), right_paw_down, false)

	# --- Key label ---
	if key_display_timer > 0.0:
		var alpha := clampf(key_display_timer / KEY_DISPLAY_DURATION, 0.0, 1.0)
		var col := Color(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, alpha)
		draw_string(ThemeDB.fallback_font, s + Vector2(0, -175), last_key,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 28, col)

	# --- Hint ---
	draw_string(ThemeDB.fallback_font, Vector2(w / 2.0, h - 18),
		"press any key!", HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
		Color(COLOR_TEXT, 0.35))

func _draw_keyboard(s: Vector2, w: float, _h: float) -> void:
	var kbd_w := w * 0.72
	var kbd_h := 54.0
	var kbd_x := s.x - kbd_w / 2.0
	var kbd_y := s.y + 155.0

	# Keyboard body
	draw_rect(Rect2(kbd_x - 4, kbd_y - 4, kbd_w + 8, kbd_h + 8),
		COLOR_OUTLINE, true, -1.0, true)
	draw_rect(Rect2(kbd_x, kbd_y, kbd_w, kbd_h), COLOR_KBD_BG, true, -1.0, true)

	# Draw key rows
	var rows := [14, 13, 12, 11]
	var row_h := 10.0
	var gap := 2.0
	for row in range(rows.size()):
		var count: int = rows[row]
		var key_w := (kbd_w - gap * (count + 1)) / count
		for col in range(count):
			var kx := kbd_x + gap + col * (key_w + gap)
			var ky := kbd_y + gap + row * (row_h + gap)
			# Light up keys on the correct side
			var lit := false
			if left_paw_down and col < count / 2:
				lit = true
			if right_paw_down and col >= count / 2:
				lit = true
			var kc2 := COLOR_KBD_LIT if lit else COLOR_KBD_KEY
			draw_rect(Rect2(kx, ky, key_w, row_h), kc2, true, -1.0, true)

func _draw_cat(s: Vector2) -> void:
	# Body (ellipse via circle scaled)
	draw_circle(s + Vector2(0, 30), 72, COLOR_CAT_BODY)

	# Head
	draw_circle(s + Vector2(0, -50), 68, COLOR_CAT_BODY)

	# Ears
	_draw_triangle(s + Vector2(-52, -105), s + Vector2(-30, -145), s + Vector2(-15, -100), COLOR_CAT_BODY)
	_draw_triangle(s + Vector2(52, -105), s + Vector2(30, -145), s + Vector2(15, -100), COLOR_CAT_BODY)
	# Inner ears
	_draw_triangle(s + Vector2(-46, -106), s + Vector2(-30, -135), s + Vector2(-20, -102), COLOR_PAW_PAD)
	_draw_triangle(s + Vector2(46, -106), s + Vector2(30, -135), s + Vector2(20, -102), COLOR_PAW_PAD)

	# Forehead stripe
	draw_circle(s + Vector2(0, -85), 10, COLOR_CAT_DARK)
	draw_circle(s + Vector2(-12, -72), 7, COLOR_CAT_DARK)
	draw_circle(s + Vector2(12, -72), 7, COLOR_CAT_DARK)

	# Eyes
	var eye_l := s + Vector2(-24, -52)
	var eye_r := s + Vector2(24, -52)
	if is_blinking:
		# Closed eyes — just a line
		draw_line(eye_l + Vector2(-10, 0), eye_l + Vector2(10, 0), COLOR_OUTLINE, 3.0)
		draw_line(eye_r + Vector2(-10, 0), eye_r + Vector2(10, 0), COLOR_OUTLINE, 3.0)
	else:
		draw_circle(eye_l, 12, Color.WHITE)
		draw_circle(eye_r, 12, Color.WHITE)
		draw_circle(eye_l, 7, COLOR_EYE)
		draw_circle(eye_r, 7, COLOR_EYE)
		draw_circle(eye_l + Vector2(2, -1), 4, COLOR_PUPIL)
		draw_circle(eye_r + Vector2(2, -1), 4, COLOR_PUPIL)
		# Shine
		draw_circle(eye_l + Vector2(-3, -4), 2, Color.WHITE)
		draw_circle(eye_r + Vector2(-3, -4), 2, Color.WHITE)

	# Nose
	draw_circle(s + Vector2(0, -35), 5, COLOR_NOSE)

	# Mouth
	draw_line(s + Vector2(0, -30), s + Vector2(-8, -22), COLOR_OUTLINE, 2.0)
	draw_line(s + Vector2(0, -30), s + Vector2(8, -22), COLOR_OUTLINE, 2.0)

	# Whiskers
	draw_line(s + Vector2(-8, -36), s + Vector2(-55, -32), COLOR_OUTLINE, 1.5)
	draw_line(s + Vector2(-8, -33), s + Vector2(-55, -38), COLOR_OUTLINE, 1.5)
	draw_line(s + Vector2(8, -36), s + Vector2(55, -32), COLOR_OUTLINE, 1.5)
	draw_line(s + Vector2(8, -33), s + Vector2(55, -38), COLOR_OUTLINE, 1.5)

func _draw_paw(pos: Vector2, is_down: bool, _is_left: bool) -> void:
	var offset := Vector2(0, 18) if is_down else Vector2.ZERO

	# Arm
	draw_rect(Rect2(pos.x - 18 + offset.x, pos.y - 10 + offset.y, 36, 44),
		COLOR_CAT_BODY, true, -1.0, true)

	# Paw circle
	draw_circle(pos + Vector2(0, 34) + offset, 22, COLOR_CAT_BODY)
	draw_circle(pos + Vector2(0, 34) + offset, 22, COLOR_OUTLINE, false, 2.0)

	# Toe beans
	draw_circle(pos + Vector2(-8, 46) + offset, 7, COLOR_PAW_PAD)
	draw_circle(pos + Vector2(8, 46) + offset, 7, COLOR_PAW_PAD)
	draw_circle(pos + Vector2(0, 50) + offset, 7, COLOR_PAW_PAD)
	draw_circle(pos + Vector2(0, 36) + offset, 9, COLOR_PAW_PAD)

	# Tap effect
	if is_down:
		draw_circle(pos + Vector2(0, 55) + offset, 5, COLOR_KBD_LIT)

func _draw_triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var pts := PackedVector2Array([a, b, c])
	draw_colored_polygon(pts, color)
