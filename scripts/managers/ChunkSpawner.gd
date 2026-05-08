extends Node

const ACTIVE_RADIUS: float = 800.0
const SPAWN_RADIUS: float = 1000.0
const MAX_AGENTS: int = 2000
const MAX_DENSITY_PER_CHUNK: float = 2.0
const SPAWN_PER_TICK: int = 3
const SPAWN_EVERY_N_TICKS: int = 10
const MIN_NUTRIENTS_TO_SPAWN: float = 0.1

var _camera_world_pos: Vector2 = Vector2.ZERO
var _last_valid_camera_pos: Vector2 = Vector2.ZERO
var spawn_bacteria_enabled: bool = true
var spawn_virus_enabled: bool = true
var spawn_protozoa_enabled: bool = false


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)


func _on_tick(tick: int) -> void:
	_update_camera_pos()
	if tick % 30 == 0:
		WorldGrid.update_active_chunks(_camera_world_pos, ACTIVE_RADIUS)
	if tick % SPAWN_EVERY_N_TICKS == 0:
		_maybe_spawn()


func _update_camera_pos() -> void:
	var cam: Node = get_tree().get_first_node_in_group("main_camera")
	if cam == null:
		return
	var pos: Vector2 = (cam as Node2D).global_position
	if pos == Vector2.ZERO:
		return
	_camera_world_pos = pos
	_last_valid_camera_pos = pos


func _maybe_spawn() -> void:
	if AgentPool._alive_count >= MAX_AGENTS:
		return
	var to_spawn: int = mini(SPAWN_PER_TICK, MAX_AGENTS - AgentPool._alive_count)
	var spawned: int = 0
	var attempts: int = 0
	while spawned < to_spawn and attempts < to_spawn * 4:
		attempts += 1
		var pos: Vector2 = _random_spawn_pos()
		if not _can_spawn_at(pos):
			continue
		var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
		var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
		if spawn_protozoa_enabled and _can_spawn_protozoa_at(pos):
			AgentPool.spawn_protozoa(pos.x, pos.y)
		elif spawn_bacteria_enabled and (not spawn_virus_enabled or randf() < 0.85):
			AgentPool.spawn_bacterium(pos.x, pos.y, _genome_for_biome(biome))
		elif spawn_virus_enabled:
			AgentPool.spawn_virus(pos.x, pos.y)
		else:
			continue
		spawned += 1


func _can_spawn_at(pos: Vector2) -> bool:
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	var nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	if nutrients < MIN_NUTRIENTS_TO_SPAWN:
		return false
	var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
	var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
	# No spawn in rock (too hostile), very rare in water
	if biome == WorldGrid.BIOME_ROCK:
		return false
	if biome == WorldGrid.BIOME_WATER and randf() > 0.15:
		return false
	var nearby: PackedInt32Array = AgentPool.get_agents_in_radius(
		pos.x, pos.y, WorldGrid.CHUNK_WORLD_SIZE
	)
	return nearby.size() < int(MAX_DENSITY_PER_CHUNK)


func _can_spawn_protozoa_at(pos: Vector2) -> bool:
	var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
	var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
	# Protozoa need humid aerobic environment — water or grass only
	if biome != WorldGrid.BIOME_WATER and biome != WorldGrid.BIOME_GRASS:
		return false
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	if WorldGrid.get_cell_value(gx, gy, "oxygen") < 0.15:
		return false
	if WorldGrid.get_cell_value(gx, gy, "water") < 0.3:
		return false
	# Need a minimum local bacteria density to sustain a predator
	var nearby: PackedInt32Array = AgentPool.get_agents_in_radius(pos.x, pos.y, 256.0)
	var bacteria_count: int = 0
	for i in nearby:
		if AgentPool.agent_type[i] == AgentPool.TYPE_BACTERIUM:
			bacteria_count += 1
	return bacteria_count >= 5


func _genome_for_biome(biome: int) -> Dictionary:
	match biome:
		WorldGrid.BIOME_WATER:
			return { "gram_positive": false, "metabolism": 0.015, "resistance": 0.6 }
		WorldGrid.BIOME_GRASS:
			return { "gram_positive": true, "metabolism": 0.025, "move_speed": 35.0 }
		WorldGrid.BIOME_WOOD:
			return { "gram_positive": true, "metabolism": 0.018, "division_threshold": 0.9 }
		WorldGrid.BIOME_ROCK:
			return {}  # never reached, filtered above
		_:  # EARTH default
			return {}


func _random_spawn_pos() -> Vector2:
	var angle := randf() * TAU
	var dist := sqrt(randf()) * SPAWN_RADIUS
	return _camera_world_pos + Vector2(cos(angle), sin(angle)) * dist
