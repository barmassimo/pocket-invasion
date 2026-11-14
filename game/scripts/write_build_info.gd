extends SceneTree

const Info = preload("res://scripts/build_info.gd")

func _initialize() -> void:
	var identity: Dictionary = Info.current()
	var file := FileAccess.open(Info.SNAPSHOT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write build identity snapshot")
		quit(1)
		return
	file.store_string(JSON.stringify(identity, "\t") + "\n")
	file.close()
	print("BUILD_IDENTITY=", Info.label(identity))
	quit()
