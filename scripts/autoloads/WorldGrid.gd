extends Node

const CHUNK_SIZE: int = 32
const CELL_SIZE: float = 8.0
const CHUNK_WORLD_SIZE: float = CHUNK_SIZE * CELL_SIZE  # 256px

const FIELD_KEYS: Array[String] = [
	"nutrients", "water", "temperature", "oxygen", "ph", "toxins", "light"
]

const BIOME_WATER: int = 0
const BIOME_EARTH: int = 1
const BIOME_GRASS: int = 2
const BIOME_WOOD:  int = 3
const BIOME_ROCK:  int = 4

const BIOME_DEFAULTS: Dictionary = {
	0: { "nutrients": 0.1, "water": 1.0, "temperature": 15.0, "oxygen": 0.15, "ph": 7.5, "toxins": 0.0, "light": 0.5 },
	1: { "nutrients": 0.5, "water": 0.4, "temperature": 20.0, "oxygen": 0.21, "ph": 6.8, "toxins": 0.0, "light": 0.9 },
	2: { "nutrients": 0.7, "water": 0.6, "temperature": 18.0, "oxygen": 0.25, "ph": 6.5, "toxins": 0.0, "light": 1.0 },
	3: { "nutrients": 0.8, "water": 0.7, "temperature": 16.0, "oxygen": 0.28, "ph": 5.5, "toxins": 0.0, "light": 0.4 },
	4: { "nutrients": 0.05, "water": 0.1, "temperature": 12.0, "oxygen": 0.21, "ph": 8.0, "toxins": 0.0, "light": 0.8 },
}

const DEFAULT_VALUES: Dictionary = {
	"nutrients": 0.5,
	"water": 0.7,
	"temperature": 25.0,
	"oxygen": 0.21,
	"ph": 7.0,
	"toxins": 0.0,
	"light": 1.0,
}

# Chunk eviction after this many seconds without being in the active set
const CHUNK_TTL: float = 300.0

var _chunks: Dictionary = {}            # Vector2i → { fields: {key: Array}, last_active: float }
var _active_chunks: Array[Vector2i] = []

const _DIFFUSE_FIELDS: Array[String] = ["nutrients", "oxygen", "toxins", "temperature"]
const _DIFFUSE_RATES: Array[float] = [0.05, 0.08, 0.03, 0.06]
const _DIFFUSE_INTERVAL: float = 0.1

var _diffuse_accumulator: float = 0.0
var _diffuse_field_idx: int = 0
var _wall_clock: float = 0.0


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)


# ── Chunk management ─────────────────────────────────────────────────────────

func get_or_create_chunk(chunk_coord: Vector2i, biome: int = BIOME_EARTH) -> Dictionary:
	if _chunks.has(chunk_coord):
		_chunks[chunk_coord]["last_active"] = _wall_clock
		return _chunks[chunk_coord]
	var defaults: Dictionary = BIOME_DEFAULTS[biome]
	var fields: Dictionary = {}
	var cells: int = CHUNK_SIZE * CHUNK_SIZE
	for key in FIELD_KEYS:
		var arr: Array[float] = []
		arr.resize(cells)
		arr.fill(defaults[key])
		fields[key] = arr
	var buf: Dictionary = {}
	for key in FIELD_KEYS:
		var arr: Array[float] = []
		arr.resize(cells)
		arr.fill(0.0)
		buf[key] = arr
	var chunk: Dictionary = { "fields": fields, "_buf": buf, "biome": biome, "last_active": _wall_clock }
	_chunks[chunk_coord] = chunk
	return chunk


func set_chunk_biome(chunk_coord: Vector2i, biome: int) -> void:
	var chunk: Dictionary = get_or_create_chunk(chunk_coord, biome)
	chunk["biome"] = biome
	var defaults: Dictionary = BIOME_DEFAULTS[biome]
	for key in FIELD_KEYS:
		chunk["fields"][key].fill(defaults[key])
		chunk["_buf"][key].fill(0.0)


func get_chunk_biome(chunk_coord: Vector2i) -> int:
	if not _chunks.has(chunk_coord):
		return BIOME_EARTH
	return _chunks[chunk_coord].get("biome", BIOME_EARTH)


func update_active_chunks(camera_world_pos: Vector2, active_radius_px: float) -> void:
	var half: float = active_radius_px
	var min_chunk: Vector2i = world_to_chunk(camera_world_pos - Vector2(half, half))
	var max_chunk: Vector2i = world_to_chunk(camera_world_pos + Vector2(half, half))
	_active_chunks.clear()
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var coord: Vector2i = Vector2i(cx, cy)
			get_or_create_chunk(coord)
			_active_chunks.append(coord)


func _evict_stale_chunks() -> void:
	var to_remove: Array[Vector2i] = []
	for coord: Vector2i in _chunks.keys():
		var age: float = _wall_clock - _chunks[coord]["last_active"]
		if age > CHUNK_TTL:
			to_remove.append(coord)
	for coord in to_remove:
		_chunks.erase(coord)


# ── Coordinate helpers ────────────────────────────────────────────────────────

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / CHUNK_WORLD_SIZE),
		floori(world_pos.y / CHUNK_WORLD_SIZE)
	)


func world_to_local(world_pos: Vector2) -> Vector2i:
	var gx: int = floori(world_pos.x / CELL_SIZE)
	var gy: int = floori(world_pos.y / CELL_SIZE)
	return Vector2i(
		((gx % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE,
		((gy % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / CELL_SIZE),
		floori(world_pos.y / CELL_SIZE)
	)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5,
		grid_pos.y * CELL_SIZE + CELL_SIZE * 0.5
	)


# ── Cell access (global grid coords) ─────────────────────────────────────────

func get_cell_value(wx: int, wy: int, key: String) -> float:
	var chunk_coord: Vector2i = Vector2i(
		floori(float(wx) / CHUNK_SIZE),
		floori(float(wy) / CHUNK_SIZE)
	)
	var chunk: Dictionary = get_or_create_chunk(chunk_coord)
	var lx: int = ((wx % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	var ly: int = ((wy % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	return chunk["fields"][key][ly * CHUNK_SIZE + lx]


func set_cell_value(wx: int, wy: int, key: String, value: float) -> void:
	var chunk_coord: Vector2i = Vector2i(
		floori(float(wx) / CHUNK_SIZE),
		floori(float(wy) / CHUNK_SIZE)
	)
	var chunk: Dictionary = get_or_create_chunk(chunk_coord)
	var lx: int = ((wx % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	var ly: int = ((wy % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	chunk["fields"][key][ly * CHUNK_SIZE + lx] = value


# ── Diffusion ─────────────────────────────────────────────────────────────────

func diffuse(key: String, rate: float) -> void:
	for coord in _active_chunks:
		_diffuse_chunk(coord, key, rate)


func _diffuse_chunk(coord: Vector2i, key: String, rate: float) -> void:
	var chunk: Dictionary = get_or_create_chunk(coord)
	var src: Array = chunk["fields"][key]
	var dst: Array = chunk["_buf"][key]
	var s: int = CHUNK_SIZE
	for y in range(1, s - 1):
		for x in range(1, s - 1):
			var idx: int = y * s + x
			var laplacian: float = (
				src[idx + 1] + src[idx - 1] +
				src[idx + s] + src[idx - s] -
				4.0 * src[idx]
			)
			dst[idx] = src[idx] + rate * laplacian
	_copy_chunk_border(src, dst, s)
	chunk["_buf"][key] = src
	chunk["fields"][key] = dst


func _copy_chunk_border(src: Array, dst: Array, s: int) -> void:
	for x in s:
		dst[x] = src[x]
		dst[(s - 1) * s + x] = src[(s - 1) * s + x]
	for y in range(1, s - 1):
		dst[y * s] = src[y * s]
		dst[y * s + s - 1] = src[y * s + s - 1]


# ── Process ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_wall_clock += delta
	_diffuse_accumulator += delta
	if _diffuse_accumulator >= _DIFFUSE_INTERVAL:
		_diffuse_accumulator -= _DIFFUSE_INTERVAL
		diffuse(_DIFFUSE_FIELDS[_diffuse_field_idx], _DIFFUSE_RATES[_diffuse_field_idx])
		_diffuse_field_idx = (_diffuse_field_idx + 1) % _DIFFUSE_FIELDS.size()
		_evict_stale_chunks()


func _on_tick(tick: int) -> void:
	if tick % 30 == 0:
		_regenerate_nutrients()


func _regenerate_nutrients() -> void:
	for coord in _active_chunks:
		if not _chunks.has(coord):
			continue
		var fields: Dictionary = _chunks[coord]["fields"]
		var arr: Array = fields["nutrients"]
		for i in arr.size():
			if arr[i] < 0.8:
				arr[i] = minf(arr[i] + 0.003, 0.8)
