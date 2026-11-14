class_name LocalHighScores
extends RefCounted

const SAVE_PATH: String = "user://high_scores.json"
const NAME_LENGTH: int = 12
const ALPHABET: String = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"
var entries: Array[Dictionary] = []

func _init() -> void:
	reset_defaults()

func reset_defaults() -> void:
	entries.clear()
	var names: Array[String] = ["AKIRA", "SOFIA", "KWAME", "INGRID", "DIEGO", "MEI", "AMIRA", "LUCA", "PRIYA", "OLIVER"]
	var points: Array[int] = [4879, 4216, 3697, 3184, 2743, 2309, 1986, 1627, 1308, 1042]
	for i: int in range(10):
		entries.append({"name": names[i], "score": points[i]})

static func clean_name(value: String) -> String:
	var result: String = ""
	for character: String in value.to_upper():
		if character in ALPHABET and result.length() < NAME_LENGTH:
			result += character
	return result.strip_edges()

func rank_for(points: int) -> int:
	for i: int in range(entries.size()):
		# Existing entries win ties; a run must beat the tenth score.
		if points > int(entries[i].score):
			return i
	return -1

func record(points: int, player_name: String) -> int:
	var rank: int = rank_for(points)
	if rank < 0:
		return -1
	var name_text: String = clean_name(player_name)
	entries.insert(rank, {"name": name_text if not name_text.is_empty() else "PILOT", "score": points})
	entries.resize(10)
	return rank

func load_scores(path: String = SAVE_PATH) -> void:
	reset_defaults()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("format") != 1 or not data.get("entries") is Array:
		return
	var rows: Array = data.entries
	if rows.size() != 10:
		return
	var loaded: Array[Dictionary] = []
	var previous: int = 2147483647
	for row: Variant in rows:
		if not row is Dictionary or not row.get("name") is String:
			return
		var points: Variant = row.get("score")
		if not (points is float or points is int):
			return
		if not is_finite(float(points)) or points < 0 or points > previous or float(points) != floorf(float(points)):
			return
		var name_text: String = clean_name(row.name)
		if name_text.is_empty():
			return
		loaded.append({"name": name_text, "score": int(points)})
		previous = int(points)
	entries = loaded

func save_scores(path: String = SAVE_PATH) -> Error:
	# Replace only a fully written file, retaining the previous table on failure.
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"format": 1, "entries": entries}))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(temporary, path)
