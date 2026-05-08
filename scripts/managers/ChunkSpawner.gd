extends Node

const SPAWN_RADIUS: float = 800.0
const MAX_AGENTS: int = 2000
const MAX_DENSITY_PER_CHUNK: float = 2.0
const SPAWN_PER_TICK: int = 3
const SPAWN_EVERY_N_TICKS: int = 10
const MIN_NUTRIENTS_TO_SPAWN: float = 0.1

var _camera_world_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)


func _on_tick(tick: int) -> void:
	_update_camera_pos()
	WorldGrid.update_active_chunks(_camera_world_pos, SPAWN_RADIUS)
	if tick % SPAWN_EVERY_N_TICKS == 0:
		_maybe_spawn()


func _update_camera_pos() -> void:
	var cam: Node = get_tree().get_first_node_in_group("main_camera")
	if cam != null:
		_camera_world_pos = (cam as Node2D).global_position


func _maybe_spawn() -> void:
	if AgentPool.get_population_count() >= MAX_AGENTS:
		return
	var to_spawn: int = mini(SPAWN_PER_TICK, MAX_AGENTS - AgentPool.get_population_count())
	var spawned: int = 0
	var attempts: int = 0
	while spawned < to_spawn and attempts < to_spawn * 4:
		attempts += 1
		var pos: Vector2 = _random_spawn_pos()
		if not _can_spawn_at(pos):
			continue
		AgentPool.spawn_bacterium(pos.x, pos.y)
		spawned += 1


func _can_spawn_at(pos: Vector2) -> bool:
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	var nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	if nutrients < MIN_NUTRIENTS_TO_SPAWN:
		return false
	var nearby: PackedInt32Array = AgentPool.get_agents_in_radius(
		pos.x, pos.y, WorldGrid.CHUNK_WORLD_SIZE
	)
	return nearby.size() < int(MAX_DENSITY_PER_CHUNK)


func _random_spawn_pos() -> Vector2:
	var half: float = SPAWN_RADIUS
	return _camera_world_pos + Vector2(
		randf_range(-half, half),
		randf_range(-half, half)
	)
