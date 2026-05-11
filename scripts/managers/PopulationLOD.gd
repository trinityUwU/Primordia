extends Node

# Aggregate: chunk_coord → PackedInt32Array[TYPE_COUNT]
# Index = agent type (0=bacterium, 1=virus, 2=protozoa, 3=plant, 4=fungi)
const TYPE_COUNT: int = 5
const CHUNK_PX: float = 256.0  # WorldGrid.CHUNK_WORLD_SIZE

var _aggregate: Dictionary = {}  # Vector2i → PackedInt32Array

var _active_chunks: Array[Vector2i] = []
var _active_set: Dictionary = {}
var _last_active_set: Dictionary = {}

var _active_radius: float = 0.0

var _last_cam_pos: Vector2 = Vector2(-999999, -999999)
var _last_radius: float = 0.0

# Deferred spawn queue — chunks entering active zone are spawned 2 per tick max
var _spawn_queue: Array[Vector2i] = []
const MAX_SPAWNS_PER_TICK: int = 2


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)


func _on_tick(tick: int) -> void:
	# Drain spawn queue every tick (not just every 10)
	if not _spawn_queue.is_empty():
		var to_spawn: int = mini(MAX_SPAWNS_PER_TICK, _spawn_queue.size())
		for _i in to_spawn:
			_spawn_from_aggregate(_spawn_queue.pop_front())

	if tick % 10 != 0:
		return
	_update_active_zone()
	# Pressure valve: if pool is near SOFT_CAP, force-aggregate outer chunks
	if AgentPool._alive_count > AgentPool.SOFT_CAP * 0.85:
		_force_aggregate_overflow()


func _force_aggregate_overflow() -> void:
	# Find chunks with agents that are NOT in the active set and aggregate them
	var camera: Camera2D = _get_camera()
	if camera == null:
		return
	var cam_pos: Vector2 = camera.global_position
	var chunk_distances: Array = []
	for coord in _last_active_set:
		if _active_set.has(coord):
			continue
		var world_center: Vector2 = Vector2(coord.x + 0.5, coord.y + 0.5) * CHUNK_PX
		var dist: float = cam_pos.distance_squared_to(world_center)
		chunk_distances.append([dist, coord])
	chunk_distances.sort_custom(func(a, b): return a[0] > b[0])  # farthest first
	var freed: int = 0
	for entry in chunk_distances:
		if AgentPool._alive_count <= AgentPool.SOFT_CAP * 0.7:
			break
		_aggregate_chunk(entry[1])
		freed += 1
		if freed >= 3:
			break


func _update_active_zone() -> void:
	var camera: Camera2D = _get_camera()
	if camera == null:
		return

	# Active radius capped — LOD only makes sense near the camera
	# At macro zoom the viewport covers huge areas but agents only exist near spawn point
	_active_radius = 1200.0  # fixed 1200px world units (~5 chunks radius)
	var cam_pos: Vector2 = camera.global_position

	var pos_delta: float = cam_pos.distance_squared_to(_last_cam_pos)
	var radius_delta: float = abs(_active_radius - _last_radius) / max(_last_radius, 1.0)
	if pos_delta < CHUNK_PX * CHUNK_PX and radius_delta < 0.15:
		return
	_last_cam_pos = cam_pos
	_last_radius = _active_radius

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

	# Chunks ENTERING active zone → enqueue for deferred spawn (2/tick max)
	for coord in new_set:
		if not _last_active_set.has(coord):
			_spawn_queue.append(coord)

	_last_active_set = new_set
	_active_set = new_set


func _aggregate_chunk(chunk_coord: Vector2i) -> void:
	# Query spatial hash — only agents near chunk center, then AABB-filter to chunk bounds
	var cx_min: float = chunk_coord.x * CHUNK_PX
	var cy_min: float = chunk_coord.y * CHUNK_PX
	var cx_max: float = cx_min + CHUNK_PX
	var cy_max: float = cy_min + CHUNK_PX
	var center_x: float = cx_min + CHUNK_PX * 0.5
	var center_y: float = cy_min + CHUNK_PX * 0.5
	# Radius covers the full chunk diagonal + one spatial cell margin
	var query_radius: float = CHUNK_PX * 0.7072 + AgentPool.SPATIAL_CELL

	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(TYPE_COUNT)
	counts.fill(0)

	var candidates: PackedInt32Array = AgentPool.get_agents_in_radius(center_x, center_y, query_radius)
	var to_kill: Array[int] = []
	for i in candidates:
		var px: float = AgentPool.pos_x[i]
		var py: float = AgentPool.pos_y[i]
		if px < cx_min or px >= cx_max or py < cy_min or py >= cy_max:
			continue
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
