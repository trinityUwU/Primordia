extends Node

signal biome_changed(chunk_coord: Vector2i)

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

const BIOME_REGEN: Dictionary = {
	0: { "nutrients": 0.008, "water": 0.02,  "oxygen": 0.018, "ph_toward": 8.1 },   # WATER — algues
	1: { "nutrients": 0.025, "water": 0.005, "oxygen": 0.010, "ph_toward": 6.5 },   # EARTH
	2: { "nutrients": 0.06,  "water": 0.015, "oxygen": 0.040, "ph_toward": 6.8 },   # GRASS — photosynthèse
	3: { "nutrients": 0.09,  "water": 0.025, "oxygen": 0.055, "ph_toward": 5.2 },   # WOOD — forêt, fort producteur O2
	4: { "nutrients": 0.003, "water": 0.001, "oxygen": 0.008, "ph_toward": 7.5 },   # ROCK
}
const BIOME_REGEN_CAP: Dictionary = {
	0: { "nutrients": 0.3,  "water": 1.0,  "oxygen": 0.28 },
	1: { "nutrients": 0.7,  "water": 0.6,  "oxygen": 0.26 },
	2: { "nutrients": 1.0,  "water": 0.8,  "oxygen": 0.45 },
	3: { "nutrients": 1.0,  "water": 0.95, "oxygen": 0.55 },
	4: { "nutrients": 0.08, "water": 0.15, "oxygen": 0.22 },
}

const BIOME_CAPACITY: Dictionary = {
	# max agents per chunk per type: [bacteria, virus, protozoa, plant, fungi]
	0: [15, 5, 3, 1, 0],    # WATER
	1: [20, 8, 4, 4, 3],    # EARTH
	2: [30, 10, 6, 6, 4],   # GRASS — plant cap réduit pour éviter monopole
	3: [35, 8, 5, 5, 8],    # WOOD — fungi dominant, plants limités
	4: [3, 2, 1, 0, 0],     # ROCK
}

const BIOME_DEFAULTS: Dictionary = {
	# WATER — ocean/lake: dissolved O2, alkaline pH, low nutrients (life supported by microbe recycling)
	0: { "nutrients": 0.15, "water": 1.0, "temperature": 15.0, "oxygen": 0.18, "ph": 8.1, "toxins": 0.0, "light": 0.6 },
	# EARTH — bare soil: moderate organic matter, moderate moisture
	1: { "nutrients": 0.35, "water": 0.35, "temperature": 20.0, "oxygen": 0.21, "ph": 6.5, "toxins": 0.0, "light": 0.9 },
	# GRASS — grassland: rich in nutrients, good moisture, full sunlight
	2: { "nutrients": 0.6,  "water": 0.55, "temperature": 18.0, "oxygen": 0.23, "ph": 6.8, "toxins": 0.0, "light": 1.0 },
	# WOOD — forest: very rich organic matter, high moisture, canopy blocks light, acidic from leaf litter
	3: { "nutrients": 0.85, "water": 0.75, "temperature": 16.0, "oxygen": 0.27, "ph": 5.2, "toxins": 0.0, "light": 0.25 },
	# ROCK — sterile mineral: almost no nutrients, dry, neutral pH
	4: { "nutrients": 0.02, "water": 0.06, "temperature": 28.0, "oxygen": 0.21, "ph": 7.5, "toxins": 0.0, "light": 0.95 },
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
var _biome_map: Dictionary = {}         # Vector2i → int — persistent, never evicted
var _biome_overrides: Dictionary = {}   # Vector2i → int — manually painted chunks only (saved to disk)
var _chunk_snapshots: Dictionary = {}   # Vector2i → {key: float} — compressed mean values for evicted chunks

const _DIFFUSE_FIELDS: Array[String] = ["nutrients", "oxygen", "temperature"]
const _DIFFUSE_RATES: Array[float] = [0.05, 0.08, 0.06]
const _DIFFUSE_INTERVAL: float = 0.1

const MAX_DIFFUSE_CHUNKS_PER_FRAME: int = 16
var _diffuse_accumulator: float = 0.0
var _diffuse_field_idx: int = 0
var _diffuse_chunk_cursor: int = 0
var _wall_clock: float = 0.0


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)


# ── Chunk management ─────────────────────────────────────────────────────────

func get_or_create_chunk(chunk_coord: Vector2i, biome: int = -1) -> Dictionary:
	if _chunks.has(chunk_coord):
		_chunks[chunk_coord]["last_active"] = _wall_clock
		return _chunks[chunk_coord]

	# Determine biome: manual override > provided > procedural
	var resolved_biome: int
	if _biome_overrides.has(chunk_coord):
		resolved_biome = _biome_overrides[chunk_coord]
	elif biome >= 0:
		resolved_biome = biome
	else:
		resolved_biome = WorldGen.get_biome(chunk_coord)

	var snap: Dictionary = _chunk_snapshots.get(chunk_coord, {})
	var cells: int = CHUNK_SIZE * CHUNK_SIZE
	var fields: Dictionary = {}
	for key in FIELD_KEYS:
		var arr: Array[float] = []
		arr.resize(cells)
		arr.fill(0.0)
		fields[key] = arr
	var buf: Dictionary = {}
	for key in FIELD_KEYS:
		var arr: Array[float] = []
		arr.resize(cells)
		arr.fill(0.0)
		buf[key] = arr

	if snap:
		# Restore evicted chunk from snapshot means
		for key in FIELD_KEYS:
			fields[key].fill(snap.get(key, BIOME_DEFAULTS[resolved_biome].get(key, 0.0)))
		_chunk_snapshots.erase(chunk_coord)
	else:
		# Fresh chunk — procedural generation
		WorldGen.generate_chunk_fields(chunk_coord, resolved_biome, fields)

	var chunk: Dictionary = { "fields": fields, "_buf": buf, "biome": resolved_biome, "last_active": _wall_clock }
	_chunks[chunk_coord] = chunk
	return chunk


func set_chunk_biome(chunk_coord: Vector2i, biome: int) -> void:
	_biome_map[chunk_coord] = biome
	_biome_overrides[chunk_coord] = biome  # mark as manual override → saved to disk
	var chunk: Dictionary = get_or_create_chunk(chunk_coord, biome)
	chunk["biome"] = biome
	var defaults: Dictionary = BIOME_DEFAULTS[biome]
	for key in FIELD_KEYS:
		chunk["fields"][key].fill(defaults[key])
		chunk["_buf"][key].fill(0.0)
	biome_changed.emit(chunk_coord)


func get_chunk_biome(chunk_coord: Vector2i) -> int:
	return _biome_overrides.get(chunk_coord, WorldGen.get_biome(chunk_coord))


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
		_snapshot_chunk(coord)
		_chunks.erase(coord)


func _snapshot_chunk(coord: Vector2i) -> void:
	var chunk: Dictionary = _chunks[coord]
	var fields: Dictionary = chunk["fields"]
	var snap: Dictionary = {}
	var cells: int = CHUNK_SIZE * CHUNK_SIZE
	for key in FIELD_KEYS:
		var arr: Array = fields[key]
		var total: float = 0.0
		for i in cells:
			total += arr[i]
		snap[key] = total / cells
	_chunk_snapshots[coord] = snap


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
	if _active_chunks.is_empty():
		return
	var limit: int = mini(MAX_DIFFUSE_CHUNKS_PER_FRAME, _active_chunks.size())
	for n in limit:
		var idx: int = (_diffuse_chunk_cursor + n) % _active_chunks.size()
		_diffuse_chunk(_active_chunks[idx], key, rate)
	_diffuse_chunk_cursor = (_diffuse_chunk_cursor + limit) % _active_chunks.size()


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
		_regenerate_fields()


func _regenerate_fields() -> void:
	for coord in _active_chunks:
		if not _chunks.has(coord):
			continue
		var chunk: Dictionary = _chunks[coord]
		var biome: int = chunk.get("biome", BIOME_EARTH)
		var regen: Dictionary = BIOME_REGEN.get(biome, BIOME_REGEN[BIOME_EARTH])
		var caps: Dictionary = BIOME_REGEN_CAP.get(biome, BIOME_REGEN_CAP[BIOME_EARTH])
		var fields: Dictionary = chunk["fields"]
		var o2_field: Array = fields["oxygen"]
		for key in ["nutrients", "water", "oxygen"]:
			var rate: float = regen.get(key, 0.0)
			if rate <= 0.0:
				continue
			var cap: float = caps.get(key, 1.0)
			var arr: Array = fields[key]
			for i in arr.size():
				if arr[i] >= cap:
					continue
				arr[i] = minf(arr[i] + rate, cap)
		# Atmospheric buffer — strong pull toward baseline 0.21
		# Models large-scale atmospheric O2 reservoir
		var o2_arr: Array = fields["oxygen"]
		for i in o2_arr.size():
			if o2_arr[i] < 0.21:
				o2_arr[i] = minf(o2_arr[i] + 0.02, 0.21)
			elif o2_arr[i] > 0.50:
				o2_arr[i] = maxf(o2_arr[i] - 0.01, 0.50)
		# Toxins naturally degrade
		var tox_arr: Array = fields["toxins"]
		for i in tox_arr.size():
			if tox_arr[i] > 0.0:
				tox_arr[i] = maxf(tox_arr[i] - 0.002, 0.0)


# ── Chunk carrying capacity ───────────────────────────────────────────────────

func get_chunk_capacity(chunk_coord: Vector2i, agent_type: int) -> int:
	var biome: int = get_chunk_biome(chunk_coord)
	var base: int = BIOME_CAPACITY[biome][agent_type]
	# Scale by current average nutrients in chunk (0-1 range)
	var chunk: Dictionary = get_or_create_chunk(chunk_coord)
	var nutrients_arr: Array = chunk["fields"]["nutrients"]
	var avg_n: float = 0.0
	# Sample 16 cells instead of all 1024 for performance
	for s in 16:
		avg_n += nutrients_arr[s * 64]  # every 64th cell
	avg_n /= 16.0
	# Scale capacity: at 0 nutrients → 20% capacity, at 1.0 → 100%
	var scale: float = 0.2 + 0.8 * clampf(avg_n, 0.0, 1.0)
	return int(base * scale)
