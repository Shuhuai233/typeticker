# Config.gd — Saves/loads all user settings to a JSON file next to the exe
extends RefCounted

const CONFIG_FILENAME := "desktoppet_config.json"

var skin: String = "whip"
var scale: float = 1.0
var opacity: float = 1.0
var counter: int = 0
var window_x: int = 100
var window_y: int = 100

func get_config_path() -> String:
	return OS.get_executable_path().get_base_dir().path_join(CONFIG_FILENAME)

func load() -> void:
	var path := get_config_path()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return
	skin      = data.get("skin",      skin)
	scale     = data.get("scale",     scale)
	opacity   = data.get("opacity",   opacity)
	counter   = data.get("counter",   counter)
	window_x  = data.get("window_x",  window_x)
	window_y  = data.get("window_y",  window_y)

func save(win_pos: Vector2i) -> void:
	window_x = win_pos.x
	window_y = win_pos.y
	var data := {
		"skin":     skin,
		"scale":    scale,
		"opacity":  opacity,
		"counter":  counter,
		"window_x": window_x,
		"window_y": window_y,
	}
	var f := FileAccess.open(get_config_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
