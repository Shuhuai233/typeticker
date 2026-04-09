extends Node2D

const VERSION := "v0.5.0"
const SKINS := ["whip", "programmer", "anime", "skeleton", "robot"]
const SKIN_LABELS := {
	"whip":       "AI Master + Wojak",
	"programmer": "Tired Programmer",
	"anime":      "Anime Girl",
	"skeleton":   "Spooky Skeleton",
	"robot":      "Robot",
}

var config: RefCounted
var current_skin: RefCounted
var torture_count: int = 0

var menu_visible: bool = false
var menu_pos: Vector2 = Vector2.ZERO
var menu_items: Array = []
var hovered_item: int = -1

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
	config.load()
	torture_count = config.counter
	scale_val     = config.scale
	opacity_val   = config.opacity

	var win := get_window()
	win.always_on_top = true
	win.borderless    = true
	win.transparent   = true
	win.unfocusable   = false
	win.position      = Vector2i(config.window_x, config.window_y)
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
	for s in SKINS:
		var check := "> " if s == config.skin else "  "
		menu_items.append({"label": check + SKIN_LABELS[s], "action": "skin:" + s})
	menu_items.append({"label": "---", "action": "sep"})
	for sv in [0.75, 1.0, 1.5]:
		var check := "> " if absf(scale_val - sv) < 0.01 else "  "
		menu_items.append({"label": check + "Scale " + str(int(sv*100)) + "%", "action": "scale:" + str(sv)})
	menu_items.append({"label": "---", "action": "sep"})
	for ov in [0.4, 0.7, 1.0]:
		var check := "> " if absf(opacity_val - ov) < 0.01 else "  "
		menu_items.append({"label": check + "Opacity " + str(int(ov*100)) + "%", "action": "opacity:" + str(ov)})
	menu_items.append({"label": "---", "action": "sep"})
	menu_items.append({"label": "  Reset Counter [Ctrl+R]", "action": "reset"})
	menu_items.append({"label": "  Quit", "action": "quit"})

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
	config.save(get_window().position)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and event.ctrl_pressed:
			torture_count = 0
			queue_redraw()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		menu_pos = event.position
		menu_visible = not menu_visible
		_build_menu()
		queue_redraw()
		return

	if menu_visible:
		if event is InputEventMouseMotion:
			hovered_item = _get_menu_item_at(event.position)
			queue_redraw()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var idx := _get_menu_item_at(event.position)
			if idx >= 0:
				_execute_menu(menu_items[idx]["action"])
			menu_visible = false
			queue_redraw()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = get_window().position - Vector2i(DisplayServer.mouse_get_position())
		else:
			dragging = false
	if event is InputEventMouseMotion and dragging:
		get_window().position = Vector2i(DisplayServer.mouse_get_position()) + drag_offset
		return

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

func _get_menu_item_at(pos: Vector2) -> int:
	var item_h := 22.0
	var menu_w := 200.0
	for i in range(menu_items.size()):
		var r := Rect2(menu_pos.x, menu_pos.y + i * item_h, menu_w, item_h)
		if r.has_point(pos) and menu_items[i]["action"] != "sep":
			return i
	return -1

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

	var cc := Color(0.95, 0.22, 0.22) if (current_skin and current_skin.is_animating) else Color(1, 1, 1)
	draw_string(ThemeDB.fallback_font, Vector2(W / 2.0, H - 10),
		str(torture_count), HORIZONTAL_ALIGNMENT_CENTER, -1, 42, cc)

	var badge := "[global]" if _hook_available else "[local]"
	var bc := Color(0.3, 0.9, 0.4, 0.5) if _hook_available else Color(1.0, 0.6, 0.2, 0.5)
	draw_string(ThemeDB.fallback_font, Vector2(W - 4, H - 4),
		VERSION + " " + badge, HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, bc)

	if menu_visible:
		_draw_menu(W, H)

func _draw_menu(W: float, H: float) -> void:
	var item_h := 22.0
	var menu_w := 200.0
	var total_h := menu_items.size() * item_h
	var mx := clampf(menu_pos.x, 0, W - menu_w)
	var my := clampf(menu_pos.y, 0, H - total_h)

	draw_rect(Rect2(mx - 2, my - 2, menu_w + 4, total_h + 4), Color(0, 0, 0, 0.88), true, -1.0, true)
	draw_rect(Rect2(mx - 2, my - 2, menu_w + 4, total_h + 4), Color(0.4, 0.35, 0.5, 0.8), false, 1.5, true)

	for i in range(menu_items.size()):
		var item = menu_items[i]
		var iy := my + i * item_h
		if item["action"] == "sep":
			draw_line(Vector2(mx + 4, iy + 11), Vector2(mx + menu_w - 4, iy + 11),
				Color(0.4, 0.35, 0.5, 0.5), 1.0)
			continue
		if i == hovered_item:
			draw_rect(Rect2(mx, iy, menu_w, item_h), Color(0.35, 0.28, 0.50, 0.85), true)
		var tc := Color(0.95, 0.85, 1.0) if i == hovered_item else Color(1, 1, 1, 0.92)
		draw_string(ThemeDB.fallback_font, Vector2(mx + 8, iy + 15),
			item["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tc)
