extends SceneTree

func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 1:
		push_error("Expected the license data output path")
		quit(1)
		return
	var file := FileAccess.open(arguments[0], FileAccess.WRITE)
	if file == null:
		push_error("Cannot write engine license data")
		quit(1)
		return
	file.store_string(JSON.stringify({
		"engine_version": Engine.get_version_info()["string"],
		"engine_license": Engine.get_license_text(),
		"copyrights": Engine.get_copyright_info(),
		"licenses": Engine.get_license_info(),
	}, "\t") + "\n")
	file.close()
	quit()
