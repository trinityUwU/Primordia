extends Node

# Aggregate: chunk_coord → PackedInt32Array[TYPE_COUNT]
# Index = agent type (0=bacterium, 1=virus, 2=protozoa, 3=plant, 4=fungi)
const TYPE_COUNT: int = 5
const CHUNK_PX: float = 256.0  # WorldGrid.CHUNK_WORLD_SIZE

var _aggregate: Dictionary = {}  # Vector2i → PackedInt32Array

var _active_chunks: Array[Vector2i] = []
var _active_set: Dictionary = {}  # Vector2i → true (fast lookup)
var _last_active_set: Dictionary = {}

var _active_radius: float = 0.0


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)


func _on_tick(tick: int) -> void:
	if tick % 10 != 0:
		return
	_update_active_zone()


func _update_active_zone() -> void:
	var camera: Camera2D = _get_camera()
	if camera == null:
		return

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	_active_radius = half.length() + CHUNK_PX * 2.0
	var cam_pos: Vector2 = camera.global_position

	# Build new active set
	var new_set: Dictionary = {}
	var min_c: Vector2i = _world_to_chunk(cam_pos - Vector2(_active_radius, _active_radius))
	var max_c: Vector2i = _world_to_chunk(cam_pos + Vector2(_active_radius, _active_radius))
	for cy in range(min_c.y, max_c.y + 1):
		for cx in range(min_c.x, max_c.x + 1):
			new_set[Vector2i(cx, cy)] = true

	# Chunks LEAVING active zone → aggregate
	for coord in _last_active_set:
		if not new_set.has(coord):
			_aggregate_chunk(coord)

	# Chunks ENTERING active zone → spawn from aggregate
	for coord in new_set:
		if not _last_active_set.has(coord):
			_spawn_from_aggregate(coord)

	_last_active_set = new_set
	_active_set = new_set


func _aggregate_chunk(chunk_coord: Vector2i) -> void:
	# Collect all living agents in this chunk and store as counts
	var cx_min: float = chunk_coord.x * CHUNK_PX
	var cy_min: float = chunk_coord.y * CHUNK_PX
	var cx_max: float = cx_min + CHUNK_PX
	var cy_max: float = cy_min + CHUNK_PX

	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(TYPE_COUNT)
	counts.fill(0)

	var to_kill: Array[int] = []
	for i in AgentPool.count:
		if AgentPool.flags[i] & AgentPool.FLAG_ALIVE == 0:
			continue
		var px: float = AgentPool.pos_x[i]
		var py: float = AgentPool.pos_y[i]
		if px >= cx_min and px < cx_max and py >= cy_min and py < cy_max:
			var t: int = AgentPool.agent_type[i]
			if t < TYPE_COUNT:
				counts[t] += 1
			to_kill.append(i)

	# Kill aggregated agents (they live on as counts)
	for i in to_kill:
		AgentPool.flags[i] &= ~AgentPool.FLAG_ALIVE
		AgentPool._alive_count -= 1
		if AgentPool.agent_type[i] < AgentPool._type_counts.size():
			AgentPool._type_counts[AgentPool.agent_type[i]] -= 1
		AgentPool.dead_timer[i] = 0  # no decay, just free the slot

	# Store counts (merge with existing)
	if not _aggregate.has(chunk_coord):
		_aggregate[chunk_coord] = counts
	else:
		var existing: PackedInt32Array = _aggregate[chunk_coord]
		for t in TYPE_COUNT:
			existing[t] += counts[t]
		_aggregate[chunk_coord] = existing


func _spawn_from_aggregate(chunk_coord: Vector2i) -> void:
	if not _aggregate.has(chunk_coord):
		return
	var counts: PackedInt32Array = _aggregate[chunk_coord]
	var cx: float = chunk_coord.x * CHUNK_PX
	var cy: float = chunk_coord.y * CHUNK_PX

	for t in TYPE_COUNT:
		var n: int = counts[t]
		if n <= 0:
			continue
		# Cap spawn to avoid RAM explosion when entering dense zones
		var to_spawn: int = mini(n, 500)
		for _j in to_spawn:
			if AgentPool._alive_count >= AgentPool.MAX_AGENTS:
				break
			var px: float = cx + randf() * CHUNK_PX
			var py: float = cy + randf() * CHUNK_PX
			match t:
				0: AgentPool.spawn_bacterium(px, py)
				1: AgentPool.spawn_virus(px, py)
				2: AgentPool.spawn_protozoa(px, py)
				3: AgentPool.spawn_plant(px, py)
				4: AgentPool.spawn_fungi(px, py)

	_aggregate.erase(chunk_coord)


func get_aggregate_count(chunk_coord: Vector2i, agent_type: int) -> int:
	if not _aggregate.has(chunk_coord):
		return 0
	return _aggregate[chunk_coord][agent_type]


func get_total_aggregate_population() -> int:
	var total: int = 0
	for coord in _aggregate:
		for t in TYPE_COUNT:
			total += _aggregate[coord][t]
	return total


func is_chunk_active(chunk_coord: Vector2i) -> bool:
	return _active_set.has(chunk_coord)


func _get_camera() -> Camera2D:
	var cam: Node = get_tree().get_first_node_in_group("main_camera")
	if cam == null:
		return null
	return cam as Camera2D


func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / CHUNK_PX),
		floori(world_pos.y / CHUNK_PX)
	)
