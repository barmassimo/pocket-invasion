class_name BuildInfo
extends RefCounted

const SNAPSHOT_PATH: String = "res://build_info.json"

static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))

static func git_output(root: String, arguments: PackedStringArray) -> Array:
	var output: Array = []
	var command := PackedStringArray(["-C", root])
	command.append_array(arguments)
	if OS.execute("git", command, output, false, false) != 0:
		return []
	return output

static func source_identity(root: String) -> Dictionary:
	# Only inspect this checkout, never an enclosing or unrelated repository.
	if not DirAccess.dir_exists_absolute(root.path_join(".git")) and not FileAccess.file_exists(root.path_join(".git")):
		return {}
	var head: Array = git_output(root, PackedStringArray(["rev-parse", "--verify", "HEAD"]))
	var state: Array = git_output(root, PackedStringArray(["status", "--porcelain", "--untracked-files=normal"]))
	if head.is_empty() or state.is_empty():
		return {}
	return validated({"version": version(), "commit": str(head[0]).strip_edges(), "modified": not str(state[0]).strip_edges().is_empty()})

static func validated(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var info: Dictionary = value
	if info.get("version", "") != version() or not info.get("commit") is String or not info.get("modified") is bool:
		return {}
	var hash_pattern := RegEx.new()
	hash_pattern.compile("^([0-9a-f]{40}|[0-9a-f]{64})$")
	if hash_pattern.search(info["commit"]) == null:
		return {}
	return {"version": version(), "commit": info["commit"], "modified": info["modified"]}

static func current() -> Dictionary:
	if OS.has_feature("editor"):
		return source_identity(ProjectSettings.globalize_path("res://").path_join("..").simplify_path())
	# Exported builds only read their bundled snapshot, with no Git dependency.
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		return {}
	return validated(JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT_PATH)))

static func label(info: Dictionary) -> String:
	var identity: Dictionary = validated(info)
	if identity.is_empty():
		return "v%s" % version()
	return "v%s-%s%s" % [version(), str(identity["commit"]).left(7), "-modified" if identity["modified"] else ""]
