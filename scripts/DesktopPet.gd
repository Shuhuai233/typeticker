extends Node2D

const VERSION := "v0.5.1"
const SKINS := ["whip", "programmer", "anime", "skeleton", "robot"]
const SKIN_LABELS := {
	"whip":       "1. AI Master + Wojak",
	"programmer": "2. Tired Programmer",
	"anime":      "3. Anime Girl",
	"skeleton":   "4. Spooky Skeleton",
	"robot":      "5. Robot",
}

var config: RefCounted
var current_skin: RefCounted
var torture_count: int = 0

# Menu — uses clamped draw position to stay in sync with hit detection
var menu_visible: bool = false
var menu_draw_pos: Vector2 = Vector2.ZERO  # actual drawn position (clamped)
var menu_items: Array = []
var hovered_item: int = -1
const MENU_ITEM_H := 22.0
const MENU_W := 200.0

# Settings gear button
var mouse_in_window: bool = false
const GEAR_RECT := Rect2(374, 4, 22, 22)  # top-right corner

var scale_val: float = 1.0
var opacity_val: float = 1.0

var dragging: bool = false
var drag_offset: Vector2i = Vector2i.ZERO

var _hook_pid: int = -1
var _hook_available: bool = false
var _count_file: String = ""
var _last_count: int = 0
var _save_timer: float = 0.0
const SAVE_INTERVAL := 5.0

func _ready() -> void:
	config = load("res://scripts/Config.gd").new()
	config.load_config()
	torture_count = config.counter
	scale_val     = config.scale
	opacity_val   = config.opacity

	var win := get_window()
	win.always_on_top = true
	win.borderless    = true
	win.transparent   = true
	win.unfocusable   = false
	win.mouse_entered.connect(func(): mouse_in_window = true;  queue_redraw())
	win.mouse_exited.connect(func():  mouse_in_window = false; menu_visible = false; queue_redraw())
	win.position = Vector2i(config.window_x, config.window_y)
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	_apply_scale()
	_load_skin(config.skin)
	_init_hook()
	_build_menu()

func _apply_scale() -> void:
	var win := get_window()
	win.size = Vector2i(int(400 * scale_val), int(240 * scale_val))
	win.content_scale_factor = scale_val
	modulate.a = opacity_val

func _load_skin(name: String) -> void:
	config.skin = name
	match name:
		"whip":       current_skin = load("res://scripts/skins/SkinWhip.gd").new()
		"programmer": current_skin = load("res://scripts/skins/SkinProgrammer.gd").new()
		"anime":      current_skin = load("res://scripts/skins/SkinAnime.gd").new()
		"skeleton":   current_skin = load("res://scripts/skins/SkinSkeleton.gd").new()
		"robot":      current_skin = load("res://scripts/skins/SkinRobot.gd").new()
		_:            current_skin = load("res://scripts/skins/SkinWhip.gd").new()

func _build_menu() -> void:
	menu_items.clear()
	# Section header
	menu_items.append({"label": "-- SKINS --", "action": "sep"})
	for s in SKINS:
		var check := "* " if s == config.skin else "  "
		menu_items.append({"label": check + SKIN_LABELS[s], "action": "skin:" + s})
	menu_items.append({"label": "-- SCALE --", "action": "sep"})
	for sv in [0.75, 1.0, 1.5]:
		var check := "* " if absf(scale_val - sv) < 0.01 else "  "
		menu_items.append({"label": check + "Scale " + str(int(sv * 100)) + "%", "action": "scale:" + str(sv)})
	menu_items.append({"label": "-- OPACITY --", "action": "sep"})
	for ov in [0.4, 0.7, 1.0]:
		var check := "* " if absf(opacity_val - ov) < 0.01 else "  "
		menu_items.append({"label": check + "Opacity " + str(int(ov * 100)) + "%", "action": "opacity:" + str(ov)})
	menu_items.append({"label": "-- ACTION --", "action": "sep"})
	menu_items.append({"label": "  Reset Counter [Ctrl+R]", "action": "reset"})
	menu_items.append({"label": "  Quit", "action": "quit"})

func _compute_menu_pos(click_pos: Vector2) -> Vector2:
	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y
	var total_h := menu_items.size() * MENU_ITEM_H
	return Vector2(
		clampf(click_pos.x, 0.0, W - MENU_W),
		clampf(click_pos.y, 0.0, H - total_h)
	)

func _init_hook() -> void:
	var exe_dir := OS.get_executable_path().get_base_dir()
	var hook_exe := exe_dir.path_join("global_input_hook.exe")
	_count_file = OS.get_temp_dir().path_join("desktoppet_count.txt")
	if FileAccess.file_exists(hook_exe):
		var pid := OS.create_process(hook_exe, [_count_file])
		if pid > 0:
			_hook_pid = pid
			_hook_available = true
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(_poll_hook)
	add_child(t)

func _poll_hook() -> void:
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
				for i in range(mini(diff, 20)):
					_trigger()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_save()
		if _hook_pid > 0:
			OS.kill(_hook_pid)

func _save() -> void:
	config.counter = torture_count
	config.scale   = scale_val
	config.opacity = opacity_val
	config.save_config(get_window().position)

func _input(event: InputEvent) -> void:
	# Ctrl+R = reset
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and event.ctrl_pressed:
			torture_count = 0
			queue_redraw()
			return

	# Right-click OR gear button = toggle menu
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_toggle_menu(event.position)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Gear button click
		if GEAR_RECT.has_point(event.position):
			_toggle_menu(Vector2(GEAR_RECT.position.x, GEAR_RECT.end.y + 2))
			return

		# Menu item click
		if menu_visible:
			var idx := _get_menu_item_at(event.position)
			if idx >= 0:
				_execute_menu(menu_items[idx]["action"])
			menu_visible = false
			queue_redraw()
			return

		# Drag start
		dragging = true
		drag_offset = get_window().position - Vector2i(DisplayServer.mouse_get_position())

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false

	if event is InputEventMouseMotion:
		if menu_visible:
			hovered_item = _get_menu_item_at(event.position)
			queue_redraw()
		elif dragging:
			get_window().position = Vector2i(DisplayServer.mouse_get_position()) + drag_offset
		else:
			queue_redraw()  # refresh gear button hover
		return

	# Local input fallback
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

func _toggle_menu(click_pos: Vector2) -> void:
	if menu_visible:
		menu_visible = false
	else:
		menu_visible = true
		_build_menu()
		menu_draw_pos = _compute_menu_pos(click_pos)
		hovered_item = -1
	queue_redraw()

func _get_menu_item_at(pos: Vector2) -> int:
	for i in range(menu_items.size()):
		var r := Rect2(menu_draw_pos.x, menu_draw_pos.y + i * MENU_ITEM_H, MENU_W, MENU_ITEM_H)
		if r.has_point(pos) and menu_items[i]["action"] != "sep":
			return i
	return -1

func _execute_menu(action: String) -> void:
	if action.begins_with("skin:"):
		_load_skin(action.substr(5))
		_build_menu()
	elif action.begins_with("scale:"):
		scale_val = action.substr(6).to_float()
		_apply_scale()
		_build_menu()
	elif action.begins_with("opacity:"):
		opacity_val = action.substr(8).to_float()
		_apply_scale()
		_build_menu()
	elif action == "reset":
		torture_count = 0
	elif action == "quit":
		_save()
		get_tree().quit()

func _trigger() -> void:
	torture_count += 1
	if current_skin:
		current_skin.trigger()

func _process(delta: float) -> void:
	if current_skin:
		if "torture_count" in current_skin:
			current_skin.torture_count = torture_count
		current_skin.update(delta)
	_save_timer += delta
	if _save_timer >= SAVE_INTERVAL:
		_save_timer = 0.0
		_save()
	queue_redraw()

func _draw() -> void:
	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y

	if current_skin:
		current_skin.draw(self, W, H)

	# Counter
	var cc := Color(0.95, 0.22, 0.22) if (current_skin and current_skin.is_animating) else Color(1, 1, 1)
	draw_string(ThemeDB.fallback_font, Vector2(W / 2.0, H - 10),
		str(torture_count), HORIZONTAL_ALIGNMENT_CENTER, -1, 42, cc)

	# Version + hook badge
	var badge := "[global]" if _hook_available else "[local]"
	var bc := Color(0.3, 0.9, 0.4, 0.4) if _hook_available else Color(1.0, 0.6, 0.2, 0.4)
	draw_string(ThemeDB.fallback_font, Vector2(W - 4, H - 4),
		VERSION + " " + badge, HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, bc)

	# Gear button — only when mouse is hovering the window
	if mouse_in_window:
		_draw_gear(GEAR_RECT)

	# Menu
	if menu_visible:
		_draw_menu()

func _draw_gear(rect: Rect2) -> void:
	var cx := rect.position.x + rect.size.x / 2.0
	var cy := rect.position.y + rect.size.y / 2.0
	var hover := GEAR_RECT.has_point(get_local_mouse_position())
	var bg_col := Color(0.5, 0.45, 0.65, 0.9) if hover else Color(0.25, 0.22, 0.32, 0.75)
	# Background circle
	draw_circle(Vector2(cx, cy), 11, bg_col)
	draw_circle(Vector2(cx, cy), 11, Color(0.6, 0.55, 0.75, 0.8), false, 1.0)
	# Gear teeth (8 small circles around center)
	for i in range(8):
		var ang := i * TAU / 8.0
		var gx := cx + cos(ang) * 7.5
		var gy := cy + sin(ang) * 7.5
		draw_circle(Vector2(gx, gy), 2.5, Color(0.9, 0.88, 0.95))
	# Center circle
	draw_circle(Vector2(cx, cy), 3.5, Color(0.9, 0.88, 0.95))

func _draw_menu() -> void:
	var total_h := menu_items.size() * MENU_ITEM_H
	var mx := menu_draw_pos.x
	var my := menu_draw_pos.y

	# Shadow
	draw_rect(Rect2(mx + 3, my + 3, MENU_W + 4, total_h + 4), Color(0, 0, 0, 0.4), true, -1.0, true)
	# Background
	draw_rect(Rect2(mx, my, MENU_W, total_h), Color(0.10, 0.09, 0.14, 0.96), true, -1.0, true)
	draw_rect(Rect2(mx, my, MENU_W, total_h), Color(0.45, 0.40, 0.58, 0.9), false, 1.5, true)

	for i in range(menu_items.size()):
		var item = menu_items[i]
		var iy := my + i * MENU_ITEM_H

		if item["action"] == "sep":
			# Section header style
			draw_rect(Rect2(mx, iy, MENU_W, MENU_ITEM_H), Color(0.18, 0.16, 0.24), true)
			draw_string(ThemeDB.fallback_font, Vector2(mx + 6, iy + 14),
				item["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.52, 0.70))
			continue

		# Hover highlight
		if i == hovered_item:
			draw_rect(Rect2(mx, iy, MENU_W, MENU_ITEM_H), Color(0.32, 0.28, 0.48, 0.9), true)

		var tc := Color(1.0, 0.95, 1.0) if i == hovered_item else Color(0.90, 0.88, 0.92)
		draw_string(ThemeDB.fallback_font, Vector2(mx + 8, iy + 15),
			item["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tc)
