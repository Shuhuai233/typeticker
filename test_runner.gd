extends SceneTree

func _init() -> void:
	print("=== DesktopPet Debug Test ===")

	# Test 1: Config
	print("\n[1] Testing Config...")
	var cfg = load("res://scripts/Config.gd").new()
	print("  Config created: ", cfg != null)
	cfg.load_config()
	print("  Config loaded. skin=", cfg.skin, " scale=", cfg.scale, " opacity=", cfg.opacity)

	# Test 2: Each skin loads without error
	var skins = ["whip", "programmer", "anime", "skeleton", "robot"]
	for s in skins:
		print("\n[2] Testing skin: ", s)
		var skin_path = "res://scripts/skins/Skin" + s.capitalize() + ".gd"
		var skin_script = load(skin_path)
		if skin_script == null:
			print("  ERROR: Failed to load ", skin_path)
			continue
		var skin_inst = skin_script.new()
		print("  Loaded OK")
		print("  is_animating=", skin_inst.is_animating)
		skin_inst.trigger()
		print("  trigger() called, is_animating=", skin_inst.is_animating)
		skin_inst.update(0.1)
		print("  update(0.1) OK")

	# Test 3: _load_skin via DesktopPet instantiation check
	print("\n[3] Checking _load_skin parameter name...")
	var dp_script = load("res://scripts/DesktopPet.gd")
	if dp_script:
		print("  DesktopPet.gd loads OK")
	else:
		print("  ERROR: DesktopPet.gd failed to load")

	print("\n=== All tests done ===")
	quit()
