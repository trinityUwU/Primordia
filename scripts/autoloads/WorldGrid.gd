extends Node

const GRID_WIDTH: int = 128
const GRID_HEIGHT: int = 128
const CELL_SIZE: float = 8.0

const FIELD_KEYS: Array[String] = [
	"nutrients", "water", "temperature", "oxygen", "ph", "toxins", "light"
]

const DEFAULT_VALUES: Dictionary = {
	"nutrients": 0.5,
	"water": 0.7,
	"temperature": 25.0,
	"oxygen": 0.21,
	"ph": 7.0,
	"toxins": 0.0,
	"light": 1.0,
}

# Each field stored as flat float Array, row-major: index = y * GRID_WIDTH + x
var _fields: Dictionary = {}
var _scratch: Dictionary = {}


func _ready() -> void:
	_allocate_arrays()
	initialize_default()
	SimulationClock.tick_processed.connect(_on_tick)


func _allocate_arrays() -> void:
	var size: int = GRID_WIDTH * GRID_HEIGHT
	for key in FIELD_KEYS:
		_fields[key] = []
		_fields[key].resize(size)
		_scratch[key] = []
		_scratch[key].resize(size)


func initialize_default() -> void:
	var size: int = GRID_WIDTH * GRID_HEIGHT
	for key in FIELD_KEYS:
		var default_val: float = DEFAULT_VALUES[key]
		for i in size:
			_fields[key][i] = default_val


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / CELL_SIZE),
		int(world_pos.y / CELL_SIZE)
	)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5,
		grid_pos.y * CELL_SIZE + CELL_SIZE * 0.5
	)


func get_cell(x: int, y: int) -> Dictionary:
	var result: Dictionary = {}
	if not _is_in_bounds(x, y):
		return result
	var idx: int = y * GRID_WIDTH + x
	for key in FIELD_KEYS:
		result[key] = _fields[key][idx]
	return result


func set_cell_value(x: int, y: int, key: String, value: float) -> void:
	if not _is_in_bounds(x, y):
		return
	_fields[key][y * GRID_WIDTH + x] = value


func get_cell_value(x: int, y: int, key: String) -> float:
	if not _is_in_bounds(x, y):
		return 0.0
	return _fields[key][y * GRID_WIDTH + x]


# Fick discrete diffusion — 5-point stencil.
# rate must satisfy: rate <= 0.25 for numerical stability (FTCS scheme).
func diffuse(key: String, rate: float) -> void:
	var src: Array = _fields[key]
	var dst: Array = _scratch[key]
	var w: int = GRID_WIDTH
	var h: int = GRID_HEIGHT
	# Interior cells
	for y in range(1, h - 1):
		var row_base: int = y * w
		for x in range(1, w - 1):
			var idx: int = row_base + x
			var laplacian: float = (
				src[idx + 1] + src[idx - 1] +
				src[idx + w] + src[idx - w] -
				4.0 * src[idx]
			)
			dst[idx] = src[idx] + rate * laplacian
	# Copy border cells unchanged (Neumann boundary: zero flux)
	_copy_border(src, dst, w, h)
	# Swap arrays
	_fields[key] = dst
	_scratch[key] = src


func _copy_border(src: Array, dst: Array, w: int, h: int) -> void:
	for x in w:
		dst[x] = src[x]
		dst[(h - 1) * w + x] = src[(h - 1) * w + x]
	for y in range(1, h - 1):
		dst[y * w] = src[y * w]
		dst[y * w + w - 1] = src[y * w + w - 1]


func _is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT


# Diffusion runs on a fixed wall-clock interval, fully decoupled from sim speed.
# One field per interval in rotation — never more than ~10 passes/sec total.
const _DIFFUSE_FIELDS: Array[String] = ["nutrients", "oxygen", "toxins", "temperature"]
const _DIFFUSE_RATES: Array[float] = [0.05, 0.08, 0.03, 0.06]
const _DIFFUSE_INTERVAL: float = 0.1  # seconds real time between diffusion passes

var _diffuse_accumulator: float = 0.0
var _diffuse_field_idx: int = 0


func _process(delta: float) -> void:
	_diffuse_accumulator += delta
	if _diffuse_accumulator >= _DIFFUSE_INTERVAL:
		_diffuse_accumulator -= _DIFFUSE_INTERVAL
		diffuse(_DIFFUSE_FIELDS[_diffuse_field_idx], _DIFFUSE_RATES[_diffuse_field_idx])
		_diffuse_field_idx = (_diffuse_field_idx + 1) % _DIFFUSE_FIELDS.size()


func _on_tick(_tick: int) -> void:
	pass
