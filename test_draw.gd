extends SceneTree

func _init() -> void:
	print("=== Scene Check ===")
	var src = FileAccess.open("res://scenes/DesktopPet.tscn", FileAccess.READ).get_as_text()
	print(src)
	
	print("\n=== DesktopPet first line ===")
	var dp = FileAccess.open("res://scripts/DesktopPet.gd", FileAccess.READ).get_as_text()
	print(dp.split("\n")[0])
	
	print("\n=== VERSION in DesktopPet ===")
	for line in dp.split("\n"):
		if "VERSION" in line:
			print(line)
			break
	quit()
