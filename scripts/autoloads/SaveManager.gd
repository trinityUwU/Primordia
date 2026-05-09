extends Node

signal autosave_triggered(slot_id: String)
signal save_completed(slot_id: String)
signal load_completed(slot_id: String)

const SAVES_DIR: String = "user://saves/"
const SETTINGS_PATH: String = "user://settings.json"
const AUTOSAVE_MIN: int = 5
const AUTOSAVE_MAX: int = 3600
const DEFAULT_AUTOSAVE_INTERVAL: int = 300

var _current_slot_id: String = ""
var _autosave_timer: Timer
var _session_start_time: float = 0.0
var _slot_playtime_base: float = 0.0
var _last_save_time: float = 0.0
var _settings: Dictionary = { "default_autosave_interval": DEFAULT_AUTOSAVE_INTERVAL }


func _ready() -> void:
	_ensure_dir(SAVES_DIR)
	_load_settings()
	_autosave_timer = Timer.new()
	_autosave_timer.one_shot = false
	_autosave_timer.autostart = false
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


# ── Public API ────────────────────────────────────────────────────────────────

func list_saves() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(SAVES_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry != "." and entry != "..":
			var meta: Dictionary = _read_meta(entry)
			if not meta.is_empty():
				result.append({
					"id": entry,
					"name": meta.get("name", entry),
					"last_saved": meta.get("last_saved", ""),
					"playtime": meta.get("playtime", 0),
					"autosave_interval": meta.get("autosave_interval", DEFAULT_AUTOSAVE_INTERVAL),
				})
		entry = dir.get_next()
	dir.list_dir_end()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["last_saved"] > b["last_saved"]
	)
	return result


func new_save(name: String) -> String:
	var slot_id: String = _generate_slot_id()
	_ensure_dir(SAVES_DIR + slot_id + "/")
	var interval: int = _settings.get("default_autosave_interval", DEFAULT_AUTOSAVE_INTERVAL)
	var meta: Dictionary = {
		"name": name,
		"created": _iso_now(),
		"last_saved": _iso_now(),
		"playtime": 0,
		"autosave_interval": interval,
		"emergence_mode": false,
	}
	_write_json(SAVES_DIR + slot_id + "/meta.json", meta)
	return slot_id


func load_save(slot_id: String) -> bool:
	var meta: Dictionary = _read_meta(slot_id)
	if meta.is_empty():
		push_error("SaveManager: slot '%s' not found" % slot_id)
		return false
	var world_data: Dictionary = _read_json(SAVES_DIR + slot_id + "/world.json")
	if not world_data.is_empty():
		_deserialize_biome_map(world_data.get("biome_map", {}))
	_current_slot_id = slot_id
	_slot_playtime_base = float(meta.get("playtime", 0))
	_session_start_time = Time.get_ticks_msec() / 1000.0
	_last_save_time = _session_start_time
	var interval: int = meta.get("autosave_interval", DEFAULT_AUTOSAVE_INTERVAL)
	_start_autosave_timer(interval)
	var emergence: bool = bool(meta.get("emergence_mode", false))
	var spawner: Node = _get_chunk_spawner()
	if spawner != null:
		spawner.emergence_mode = emergence
	load_completed.emit(slot_id)
	return true


func save_current(slot_id: String) -> void:
	var meta: Dictionary = _read_meta(slot_id)
	if meta.is_empty():
		push_error("SaveManager: cannot save — slot '%s' not found" % slot_id)
		return
	meta["last_saved"] = _iso_now()
	meta["playtime"] = _compute_total_playtime()
	var spawner: Node = _get_chunk_spawner()
	if spawner != null:
		meta["emergence_mode"] = spawner.emergence_mode
	_write_json(SAVES_DIR + slot_id + "/meta.json", meta)
	var world_data: Dictionary = { "biome_map": _serialize_biome_map() }
	_write_json(SAVES_DIR + slot_id + "/world.json", world_data)
	_last_save_time = Time.get_ticks_msec() / 1000.0
	save_completed.emit(slot_id)


func delete_save(slot_id: String) -> void:
	var path: String = SAVES_DIR + slot_id + "/"
	for file_name in ["meta.json", "world.json"]:
		if FileAccess.file_exists(path + file_name):
			DirAccess.remove_absolute(path + file_name)
	DirAccess.remove_absolute(path.rstrip("/"))
	if _current_slot_id == slot_id:
		_current_slot_id = ""
		_autosave_timer.stop()


func get_current_slot_id() -> String:
	return _current_slot_id


func get_settings() -> Dictionary:
	return _settings.duplicate()


func save_settings(data: Dictionary) -> void:
	var interval: int = clampi(
		int(data.get("default_autosave_interval", DEFAULT_AUTOSAVE_INTERVAL)),
		AUTOSAVE_MIN, AUTOSAVE_MAX
	)
	_settings["default_autosave_interval"] = interval
	_write_json(SETTINGS_PATH, _settings)


func set_slot_autosave_interval(slot_id: String, interval_sec: int) -> void:
	var clamped: int = clampi(interval_sec, AUTOSAVE_MIN, AUTOSAVE_MAX)
	var meta: Dictionary = _read_meta(slot_id)
	if meta.is_empty():
		return
	meta["autosave_interval"] = clamped
	_write_json(SAVES_DIR + slot_id + "/meta.json", meta)
	if slot_id == _current_slot_id:
		_start_autosave_timer(clamped)


func get_time_since_last_save() -> float:
	if _last_save_time <= 0.0:
		return 0.0
	return Time.get_ticks_msec() / 1000.0 - _last_save_time


# ── Internal ──────────────────────────────────────────────────────────────────

func _start_autosave_timer(interval_sec: int) -> void:
	var clamped: int = clampi(interval_sec, AUTOSAVE_MIN, AUTOSAVE_MAX)
	_autosave_timer.wait_time = float(clamped)
	_autosave_timer.start()


func _on_autosave_timeout() -> void:
	if _current_slot_id == "":
		return
	save_current(_current_slot_id)
	autosave_triggered.emit(_current_slot_id)


func _compute_total_playtime() -> int:
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _session_start_time
	return int(_slot_playtime_base + elapsed)


func _serialize_biome_map() -> Dictionary:
	var result: Dictionary = {}
	for coord: Vector2i in WorldGrid._biome_map.keys():
		result["%d,%d" % [coord.x, coord.y]] = WorldGrid._biome_map[coord]
	return result


func _deserialize_biome_map(data: Dictionary) -> void:
	WorldGrid._biome_map.clear()
	for key: String in data.keys():
		var parts: PackedStringArray = key.split(",")
		if parts.size() != 2:
			continue
		var coord: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
		WorldGrid._biome_map[coord] = int(data[key])


func _read_meta(slot_id: String) -> Dictionary:
	return _read_json(SAVES_DIR + slot_id + "/meta.json")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open '%s'" % path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("SaveManager: JSON parse failed for '%s'" % path)
	return {}


func _write_json(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write '%s'" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)


func _load_settings() -> void:
	var data: Dictionary = _read_json(SETTINGS_PATH)
	if not data.is_empty():
		_settings = data


func _generate_slot_id() -> String:
	return "save_%d" % int(Time.get_unix_time_from_system())


func _get_chunk_spawner() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("chunk_spawner")


func _iso_now() -> String:
	return Time.get_datetime_string_from_system()
