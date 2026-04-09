extends SceneTree

func _init() -> void:
	print("=== DesktopPet Debug Test ===")

	# [1] Config
	print("\n[1] Config...")
	var cfg = load("res://scripts/Config.gd").new()
	cfg.load_config()
	print("  skin=", cfg.skin, " scale=", cfg.scale, " opacity=", cfg.opacity)

	# [2] Skins
	var skins = ["whip", "programmer", "anime", "skeleton", "robot"]
	for s in skins:
		var path = "res://scripts/skins/Skin" + s.capitalize() + ".gd"
		var script = load(path)
		if script == null:
			print("  ERROR loading skin: ", s)
			continue
		var inst = script.new()
		inst.trigger()
		inst.update(0.1)
		print("  skin ", s, ": OK")

	# [3] DesktopPet
	print("\n[3] DesktopPet.gd checks...")
	var dp_src = FileAccess.open("res://scripts/DesktopPet.gd", FileAccess.READ).get_as_text()
	for line in dp_src.split("\n"):
		if "VERSION" in line and ":=" in line:
			print("  ", line.strip_edges())
			break
	print("  _load_skin_by_id present: ", "_load_skin_by_id" in dp_src)

	# [4] Menu items check
	print("\n[4] Menu build check...")
	var in_menu = false
	var append_lines = []
	for line in dp_src.split("\n"):
		if "func _build_menu" in line:
			in_menu = true
			continue
		if in_menu and line.begins_with("func "):
			break
		if in_menu and "append" in line:
			append_lines.append(line.strip_edges())
	print("  Menu has ", append_lines.size(), " append calls")
	for l in append_lines:
		print("    ", l)

	print("\n=== Done ===")
	quit()
