extends Node2D

# ── State ──────────────────────────────────────────────────────────────────
var torture_count: int = 0
var is_animating: bool = false

var whip_t: float = 0.0
var react_t: float = 0.0
const ANIM_SPEED := 4.0
const IDLE_RETURN := 3.0

var idle_t: float = 0.0

var dragging := false
var drag_offset := Vector2i.ZERO

# Global hook via background EXE + temp file polling
var _hook_pid: int = -1
var _hook_available: bool = false
var _count_file: String = ""
var _last_count: int = 0

# ── Colors ───────────────────────────────────────────────────────────────────
const C_OUTLINE  := Color(0.08, 0.06, 0.10)
const C_AI_BODY  := Color(0.95, 0.40, 0.10)
const C_AI_LOGO  := Color(1.00, 1.00, 1.00)
const C_SKIN     := Color(0.95, 0.85, 0.72)
const C_DARK     := Color(0.20, 0.18, 0.22)
const C_WHIP     := Color(0.08, 0.05, 0.05)
const C_WOJAK    := Color(0.88, 0.78, 0.68)
const C_TEAR     := Color(0.45, 0.65, 0.95)
const C_TEXT_TOP := Color(0.95, 0.22, 0.22)
const C_TEXT_BOT := Color(0.85, 0.72, 0.20)
const C_COUNTER  := Color(1.00, 1.00, 1.00)

# ── Init ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	var win := get_window()
	win.always_on_top = true
	win.borderless = true
	win.transparent = true
	win.unfocusable = false
	win.size = Vector2i(400, 240)
	win.position = Vector2i(100, 100)
	# Clear to transparent — required for per-pixel transparency to work
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	_init_hook()

func _init_hook() -> void:
	# Hook EXE lives next to desktoppet.exe
	var exe_dir := OS.get_executable_path().get_base_dir()
	var hook_exe := exe_dir.path_join("global_input_hook.exe")
	_count_file = OS.get_temp_dir().path_join("desktoppet_count.txt")

	if FileAccess.file_exists(hook_exe):
		# Launch hook as detached background process
		var pid = OS.create_process(hook_exe, [_count_file])
		if pid > 0:
			_hook_pid = pid
			_hook_available = true

	# Poll timer — runs whether hook available or not (for local fallback display)
	var timer := Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	timer.timeout.connect(_poll_count)
	add_child(timer)

func _poll_count() -> void:
	if not _hook_available:
		return
	if FileAccess.file_exists(_count_file):
		var f := FileAccess.open(_count_file, FileAccess.READ)
		if f:
			var val := f.get_as_text().strip_edges().to_int()
			f.close()
			if val > _last_count:
				var diff := val - _last_count
				_last_count = val
				for i in range(min(diff, 20)):
					_trigger()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		# Kill the hook process on exit
		if _hook_pid > 0:
			OS.kill(_hook_pid)

# ── Input (fallback when hook not available) ──────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = get_window().position - Vector2i(DisplayServer.mouse_get_position())
		else:
			dragging = false
	if event is InputEventMouseMotion and dragging:
		get_window().position = Vector2i(DisplayServer.mouse_get_position()) + drag_offset

	if _hook_available:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_trigger()
	if event is InputEventMouseButton and event.pressed:
		_trigger()
	if event is InputEventJoypadButton and event.pressed:
		_trigger()
	if event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		_trigger()

func _trigger() -> void:
	torture_count += 1
	is_animating = true
	whip_t = 0.0
	react_t = 0.0

# ── Process ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	idle_t += delta * 1.2
	if is_animating:
		whip_t = min(whip_t + delta * ANIM_SPEED, 1.0)
		react_t = min(react_t + delta * ANIM_SPEED, 1.0)
		if whip_t >= 1.0 and react_t >= 1.0:
			whip_t = min(whip_t + delta * IDLE_RETURN, 2.0)
			if whip_t >= 2.0:
				is_animating = false
				whip_t = 0.0
				react_t = 0.0
	queue_redraw()

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y

	# No background — fully transparent like Bongo Cat
	# Only drawn elements are visible, rest is see-through

	# Top text
	draw_string(ThemeDB.fallback_font, Vector2(W / 2.0, 18),
		"折磨自己吧", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, C_TEXT_TOP)

	# Characters
	_draw_ai_master(Vector2(110, 90))
	_draw_wojak(Vector2(270, 105))

	# Bottom label
	draw_string(ThemeDB.fallback_font, Vector2(W / 2.0, H - 58),
		"工具人", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, C_TEXT_BOT)

	# Big counter
	var counter_col := C_TEXT_TOP if is_animating else C_COUNTER
	draw_string(ThemeDB.fallback_font, Vector2(W / 2.0, H - 10),
		str(torture_count), HORIZONTAL_ALIGNMENT_CENTER, -1, 42, counter_col)

	# Status badge
	var badge := "[global]" if _hook_available else "[local - needs hook]"
	var badge_col := Color(0.3, 0.9, 0.4, 0.7) if _hook_available else Color(1.0, 0.6, 0.2, 0.7)
	draw_string(ThemeDB.fallback_font, Vector2(4, 12),
		badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, badge_col)

# ── Left character ────────────────────────────────────────────────────────────
func _draw_ai_master(pos: Vector2) -> void:
	var sway := sin(idle_t) * 2.0
	draw_line(pos + Vector2(-8, 30 + sway), pos + Vector2(-14, 60 + sway), C_OUTLINE, 2.5)
	draw_line(pos + Vector2(8, 30 + sway),  pos + Vector2(14, 60 + sway),  C_OUTLINE, 2.5)
	draw_line(pos + Vector2(-18, 0 + sway), pos + Vector2(-30, 20 + sway), C_OUTLINE, 2.5)
	draw_line(pos + Vector2(-30, 20 + sway), pos + Vector2(-35, 35 + sway), C_OUTLINE, 2.0)
	var body_rect := Rect2(pos + Vector2(-20, -30 + sway), Vector2(40, 40))
	draw_rect(body_rect, C_AI_BODY, true, -1.0, true)
	draw_rect(body_rect, C_OUTLINE, false, 2.0, true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-14, -4 + sway),
		"Ai", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_AI_LOGO)
	var head_pos := pos + Vector2(0, -48 + sway)
	draw_circle(head_pos, 18, C_SKIN)
	draw_circle(head_pos, 18, C_OUTLINE, false, 1.5)
	draw_line(head_pos + Vector2(-8, -4), head_pos + Vector2(-3, -6), C_OUTLINE, 2.0)
	draw_line(head_pos + Vector2(3, -6),  head_pos + Vector2(8, -4),  C_OUTLINE, 2.0)
	var grin_pts := PackedVector2Array()
	for i in range(9):
		var a := deg_to_rad(-20.0 + i * 5.0)
		grin_pts.append(head_pos + Vector2(cos(a) * 10, sin(a) * 6 + 6))
	draw_polyline(grin_pts, C_OUTLINE, 2.0)
	_draw_whip_arm(pos + Vector2(18, -5 + sway))

func _draw_whip_arm(shoulder: Vector2) -> void:
	var strike_phase := 0.0
	if is_animating:
		strike_phase = sin(whip_t * PI) if whip_t <= 1.0 else sin((2.0 - whip_t) * PI)
	var arm_angle := deg_to_rad(-30.0 + strike_phase * 80.0)
	var elbow := shoulder + Vector2(cos(arm_angle) * 22, sin(arm_angle) * 22)
	var hand  := elbow + Vector2(cos(arm_angle + deg_to_rad(20)) * 18, sin(arm_angle + deg_to_rad(20)) * 18)
	draw_line(shoulder, elbow, C_OUTLINE, 2.5)
	draw_line(elbow, hand, C_OUTLINE, 2.0)
	var crack := strike_phase
	var ctrl1 := hand + Vector2(20 + crack * 40, -10 - crack * 30)
	var ctrl2 := hand + Vector2(50 + crack * 30, 10 + crack * 20)
	var tip   := hand + Vector2(70 + crack * 20, -5 + crack * 35)
	var whip_pts := PackedVector2Array()
	for i in range(12):
		whip_pts.append(_cubic_bezier(hand, ctrl1, ctrl2, tip, i / 11.0))
	draw_polyline(whip_pts, C_WHIP, 2.5)
	if crack > 0.7:
		var alpha := (crack - 0.7) / 0.3
		draw_circle(tip, 5.0 * alpha, Color(1.0, 0.9, 0.3, alpha))
		draw_circle(tip, 3.0 * alpha, Color(1.0, 1.0, 1.0, alpha))

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3

# ── Right character ───────────────────────────────────────────────────────────
func _draw_wojak(pos: Vector2) -> void:
	var flinch := Vector2.ZERO
	if is_animating and react_t <= 1.0:
		flinch = Vector2(sin(react_t * PI) * 8.0, -sin(react_t * PI) * 4.0)
	var p := pos + flinch
	draw_line(p + Vector2(-10, 10), p + Vector2(-20, 40), C_OUTLINE, 2.5)
	draw_line(p + Vector2(5, 10),   p + Vector2(15, 40),  C_OUTLINE, 2.5)
	draw_line(p + Vector2(-20, 40), p + Vector2(-25, 55), C_OUTLINE, 2.5)
	draw_line(p + Vector2(15, 40),  p + Vector2(20, 55),  C_OUTLINE, 2.5)
	draw_circle(p + Vector2(0, 0), 16, C_WOJAK)
	draw_circle(p + Vector2(0, 0), 16, C_OUTLINE, false, 1.5)
	draw_string(ThemeDB.fallback_font, p + Vector2(-8, 6),
		"Ai", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(C_AI_BODY, 0.7))
	draw_line(p + Vector2(-14, -5), p + Vector2(-28, 20), C_OUTLINE, 2.0)
	draw_line(p + Vector2(14, -5),  p + Vector2(28, 20),  C_OUTLINE, 2.0)
	var head := p + Vector2(0, -38)
	draw_circle(head, 22, C_WOJAK)
	draw_circle(head, 22, C_OUTLINE, false, 1.5)
	draw_line(head + Vector2(-18, -10), head + Vector2(-22, -22), C_DARK, 3.0)
	draw_line(head + Vector2(-10, -20), head + Vector2(-12, -26), C_DARK, 3.0)
	draw_line(head + Vector2(0, -22),   head + Vector2(0, -28),   C_DARK, 3.0)
	draw_line(head + Vector2(10, -20),  head + Vector2(12, -26),  C_DARK, 3.0)
	_draw_sad_eye(head + Vector2(-9, -5), react_t)
	_draw_sad_eye(head + Vector2(9, -5),  react_t)
	var tear_alpha := 1.0 if not is_animating else 0.5 + sin(react_t * PI * 3) * 0.5
	draw_line(head + Vector2(-9, 0),  head + Vector2(-11, 14), Color(C_TEAR, tear_alpha), 2.0)
	draw_line(head + Vector2(9, 0),   head + Vector2(11, 14),  Color(C_TEAR, tear_alpha), 2.0)
	var tremble := sin(react_t * PI * 8) * 2.0 if is_animating else 0.0
	var mouth_pts := PackedVector2Array()
	for i in range(7):
		var t := i / 6.0
		mouth_pts.append(head + Vector2(-8 + t * 16, 10 + sin(t * PI) * 3 + tremble))
	draw_polyline(mouth_pts, C_OUTLINE, 1.5)
	if is_animating and react_t < 0.6:
		var mark := p + Vector2(30, -20)
		var a := Color(1.0, 0.2, 0.2, 1.0 - react_t / 0.6)
		draw_line(mark + Vector2(-6, -6), mark + Vector2(6, 6),  a, 2.5)
		draw_line(mark + Vector2(6, -6),  mark + Vector2(-6, 6), a, 2.5)

func _draw_sad_eye(center: Vector2, react: float) -> void:
	draw_circle(center, 6, Color.WHITE)
	draw_circle(center, 6, C_OUTLINE, false, 1.0)
	var pupil_offset := Vector2(0, 2 + react * 2) if is_animating else Vector2(0, 2)
	draw_circle(center + pupil_offset, 3, C_DARK)
	var droop := 0.3 + (react * 0.4 if is_animating else 0.0)
	draw_arc(center, 6, 0, PI, 16, C_OUTLINE, 2.0)
	draw_line(center + Vector2(-6, -droop * 4), center + Vector2(6, -droop * 4), C_OUTLINE, 2.0)
