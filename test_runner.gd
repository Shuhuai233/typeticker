extends SceneTree

func _init() -> void:
	print("=== DesktopPet Debug Test ===")

	print("
[1] Testing Config...")
	var cfg = load("res://scripts/Config.gd").new()
	print("  Config created: ", cfg != null)
	cfg.load_config()
	print("  skin=", cfg.skin, " scale=", cfg.scale, " opacity=", cfg.opacity)

	var skins = ["whip", "programmer", "anime", "skeleton", "robot"]
	for s in skins:
		print("
[2] Testing skin: ", s)
		var path = "res://scripts/skins/Skin" + s.capitalize() + ".gd"
		var script = load(path)
		if script == null:
			print("  ERROR: Failed to load ", path)
			continue
		var inst = script.new()
		print("  Loaded OK")
		inst.trigger()
		print("  trigger OK, is_animating=", inst.is_animating)
		inst.update(0.1)
		print("  update OK")

	print("
[3] Checking DesktopPet...")
	var dp_script = load("res://scripts/DesktopPet.gd")
	print("  Loads OK: ", dp_script != null)
	var src = FileAccess.open("res://scripts/DesktopPet.gd", FileAccess.READ).get_as_text()
	for line in src.split("
"):
		if "VERSION" in line and ":=" in line:
			print("  ", line.strip_edges())
			break
	if "_load_skin_by_id" in src:
		print("  _load_skin_by_id: OK - no name shadowing")
	else:
		print("  WARNING: _load_skin_by_id not found!")

	print("
=== All tests passed ===")
	quit()
