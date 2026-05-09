extends Node2D

signal territory_clicked(chunk_coord: Vector2i, agents: Array[int])

const MIN_DENSITY: int = 3
const UPDATE_INTERVAL: float = 1.5
const CHUNK_SIZE: float = WorldGrid.CHUNK_WORLD_SIZE

const TYPE_COLORS: Array[Color] = [
	Color(0.310, 0.765, 0.969, 1.0),
	Color(0.937, 0.604, 0.604, 1.0),
	Color(0.808, 0.576, 0.847, 1.0),
	Color(0.647, 0.839, 0.655, 1.0),
	Color(1.000, 0.800, 0.502, 1.0),
]

var active_types: Array[bool] = [false, false, false, false, false]

var _timer: float = 0.0
var _territory_chunks: Dictionary = {}  # Vector2i → Color
var _shader: Shader = null
var _mesh_pool: Array[MeshInstance2D] = []
var _pool_size: int = 0
var _time_accum: float = 0.0
var _quad_mesh: QuadMesh = null


func _ready() -> void:
	add_to_group("territory_overlay")
	_shader = load("res://shaders/territory.gdshader")
	_quad_mesh = QuadMesh.new()
	_quad_mesh.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	z_index = 5


func set_type_active(type_idx: int, active: bool) -> void:
	if type_idx < 0 or type_idx >= 5:
		return
	active_types[type_idx] = active
	_rebuild_territory()


func _process(delta: float) -> void:
	_time_accum += delta
	_timer += delta
	if _timer >= UPDATE_INTERVAL:
		_timer = 0.0
		_rebuild_territory()
	_update_time()


func _update_time() -> void:
	for mi in _mesh_pool:
		if mi.visible:
			(mi.material as ShaderMaterial).set_shader_parameter("time", _time_accum)


func _rebuild_territory() -> void:
	_territory_chunks.clear()

	var any_active: bool = false
	for a in active_types:
		if a:
			any_active = true
			break
	if not any_active:
		_hide_all()
		return

	var chunk_data: Dictionary = {}
	var pool := AgentPool
	var n: int = pool.count

	for i in n:
		if not pool.is_alive(i):
			continue
		var t: int = pool.agent_type[i]
		if t < 0 or t >= 5 or not active_types[t]:
			continue
		var coord := Vector2i(
			floori(pool.pos_x[i] / CHUNK_SIZE),
			floori(pool.pos_y[i] / CHUNK_SIZE)
		)
		if not chunk_data.has(coord):
			chunk_data[coord] = [0, 0, 0, 0, 0]
		chunk_data[coord][t] += 1

	for coord in chunk_data:
		var counts: Array = chunk_data[coord]
		var total: int = 0
		for c in counts:
			total += c
		if total >= MIN_DENSITY:
			_territory_chunks[coord] = _blend_color(counts)

	_render()


func _blend_color(counts: Array) -> Color:
	var col := Color(0, 0, 0, 0)
	var weight: float = 0.0
	for t in 5:
		if counts[t] > 0:
			col += TYPE_COLORS[t]
			weight += 1.0
	if weight > 0.0:
		col /= weight
		col.a = 1.0
	return col


func _render() -> void:
	var needed: int = _territory_chunks.size()
	_ensure_pool(needed)

	var idx: int = 0
	for coord in _territory_chunks:
		var mi: MeshInstance2D = _mesh_pool[idx]
		# Center of chunk in world space (QuadMesh centered at origin)
		mi.position = Vector2(coord.x * CHUNK_SIZE + CHUNK_SIZE * 0.5,
							  coord.y * CHUNK_SIZE + CHUNK_SIZE * 0.5)
		(mi.material as ShaderMaterial).set_shader_parameter("color", _territory_chunks[coord])
		(mi.material as ShaderMaterial).set_shader_parameter("time", _time_accum)
		mi.visible = true
		idx += 1

	for i in range(idx, _pool_size):
		_mesh_pool[i].visible = false


func _ensure_pool(needed: int) -> void:
	while _pool_size < needed:
		var mi := MeshInstance2D.new()
		mi.mesh = _quad_mesh
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mi.material = mat
		add_child(mi)
		_mesh_pool.append(mi)
		_pool_size += 1


func _hide_all() -> void:
	for mi in _mesh_pool:
		mi.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _territory_chunks.is_empty():
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	var world_pos: Vector2 = get_global_mouse_position()
	var coord := Vector2i(
		floori(world_pos.x / CHUNK_SIZE),
		floori(world_pos.y / CHUNK_SIZE)
	)
	if not _territory_chunks.has(coord):
		return

	territory_clicked.emit(coord, _get_agents_in_chunk(coord))
	get_viewport().set_input_as_handled()


func _get_agents_in_chunk(coord: Vector2i) -> Array[int]:
	var result: Array[int] = []
	var pool := AgentPool
	for i in pool.count:
		if not pool.is_alive(i):
			continue
		if Vector2i(floori(pool.pos_x[i] / CHUNK_SIZE), floori(pool.pos_y[i] / CHUNK_SIZE)) == coord:
			result.append(i)
	return result
