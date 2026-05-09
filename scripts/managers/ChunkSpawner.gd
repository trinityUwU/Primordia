extends Node

const ACTIVE_RADIUS: float = 800.0
const SPAWN_RADIUS: float = 1000.0
const MAX_AGENTS: int = 10000
const SEED_TARGET: int = 50        # agents to seed at startup
const SPAWN_PER_TICK: int = 2
const SPAWN_EVERY_N_TICKS: int = 30  # slow trickle for immigration only
const MIN_NUTRIENTS_TO_SPAWN: float = 0.05

var _camera_world_pos: Vector2 = Vector2.ZERO
var _last_valid_camera_pos: Vector2 = Vector2.ZERO
var spawn_bacteria_enabled: bool = true
var spawn_virus_enabled: bool = true
var spawn_protozoa_enabled: bool = true
var spawn_plant_enabled: bool = true
var spawn_fungi_enabled: bool = true
var emergence_mode: bool = false


func _ready() -> void:
	add_to_group("chunk_spawner")
	SimulationClock.tick_processed.connect(_on_tick)
	call_deferred("_seed_world")


func _seed_world() -> void:
	if emergence_mode:
		return
	_update_camera_pos()
	WorldGrid.update_active_chunks(_camera_world_pos, ACTIVE_RADIUS)
	var attempts: int = 0
	while AgentPool._alive_count < SEED_TARGET and attempts < SEED_TARGET * 6:
		attempts += 1
		var pos: Vector2 = _random_spawn_pos()
		var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
		var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
		if WorldGrid.get_cell_value(gx, gy, "nutrients") < MIN_NUTRIENTS_TO_SPAWN:
			continue
		var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
		var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
		AgentPool.spawn_bacterium(pos.x, pos.y, _genome_for_biome(biome))
	for _i in 4:
		var pos: Vector2 = _random_spawn_pos()
		AgentPool.spawn_protozoa(pos.x, pos.y)
	for _i in 15:
		var pos: Vector2 = _random_spawn_pos()
		var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
		var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
		if biome != WorldGrid.BIOME_ROCK and biome != WorldGrid.BIOME_WATER:
			AgentPool.spawn_plant(pos.x, pos.y)
	for _i in 12:
		var pos: Vector2 = _random_spawn_pos()
		AgentPool.spawn_fungi(pos.x, pos.y)


func _on_tick(tick: int) -> void:
	_update_camera_pos()
	if tick % 30 == 0:
		WorldGrid.update_active_chunks(_camera_world_pos, ACTIVE_RADIUS)
	if tick % SPAWN_EVERY_N_TICKS == 0 and AgentPool._alive_count < MAX_AGENTS / 4:
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
	if emergence_mode:
		_maybe_spawn_emergence()
		return
	if AgentPool._alive_count >= AgentPool.SOFT_CAP:
		return
	var to_spawn: int = mini(SPAWN_PER_TICK, AgentPool.SOFT_CAP - AgentPool._alive_count)
	var spawned: int = 0
	var attempts: int = 0
	while spawned < to_spawn and attempts < to_spawn * 8:
		attempts += 1
		var pos: Vector2 = _random_spawn_pos()
		if not _can_spawn_at(pos):
			continue
		var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
		var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
		if spawn_protozoa_enabled and randf() < 0.12 and AgentPool._type_counts[AgentPool.TYPE_BACTERIUM] > 200:
			AgentPool.spawn_protozoa(pos.x, pos.y)
		elif spawn_plant_enabled and _can_spawn_plant_at(pos) and randf() < 0.40:
			AgentPool.spawn_plant(pos.x, pos.y)
		elif spawn_fungi_enabled and _can_spawn_fungi_at(pos) and randf() < 0.15:
			AgentPool.spawn_fungi(pos.x, pos.y)
		elif spawn_bacteria_enabled and (not spawn_virus_enabled or randf() < 0.85):
			AgentPool.spawn_bacterium(pos.x, pos.y, _genome_for_biome(biome))
		elif spawn_virus_enabled:
			AgentPool.spawn_virus(pos.x, pos.y)
		else:
			continue
		spawned += 1


func _maybe_spawn_emergence() -> void:
	if AgentPool._alive_count >= AgentPool.SOFT_CAP:
		return
	if randf() >= 0.002:
		return
	var pos: Vector2 = _random_spawn_pos()
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	var nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	var oxygen: float = WorldGrid.get_cell_value(gx, gy, "oxygen")
	var water: float = WorldGrid.get_cell_value(gx, gy, "water")
	var temperature: float = WorldGrid.get_cell_value(gx, gy, "temperature")
	if nutrients < 0.25 or oxygen < 0.18 or water < 0.20:
		return
	if temperature < 10.0 or temperature > 40.0:
		return
	var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
	var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
	if biome == WorldGrid.BIOME_ROCK:
		return
	if randf() < 0.6:
		AgentPool.spawn_bacterium(pos.x, pos.y, _genome_for_biome(biome))
	else:
		AgentPool.spawn_fungi(pos.x, pos.y)


func _can_spawn_at(pos: Vector2) -> bool:
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	var nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	if nutrients < MIN_NUTRIENTS_TO_SPAWN:
		return false
	var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
	var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
	if biome == WorldGrid.BIOME_ROCK:
		return false
	if biome == WorldGrid.BIOME_WATER and randf() > 0.4:
		return false
	return true


func _can_spawn_plant_at(pos: Vector2) -> bool:
	var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
	var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
	if biome == WorldGrid.BIOME_ROCK or biome == WorldGrid.BIOME_WATER:
		return false
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	return WorldGrid.get_cell_value(gx, gy, "light") > 0.15


func _can_spawn_fungi_at(pos: Vector2) -> bool:
	var chunk_coord: Vector2i = WorldGrid.world_to_chunk(pos)
	var biome: int = WorldGrid.get_chunk_biome(chunk_coord)
	if biome == WorldGrid.BIOME_ROCK or biome == WorldGrid.BIOME_WATER:
		return false
	var gx: int = int(pos.x / WorldGrid.CELL_SIZE)
	var gy: int = int(pos.y / WorldGrid.CELL_SIZE)
	return WorldGrid.get_cell_value(gx, gy, "nutrients") > 0.1


func _genome_for_biome(biome: int) -> Dictionary:
	match biome:
		WorldGrid.BIOME_WATER:
			return { "gram_positive": false, "metabolism": 0.015, "resistance": 0.6 }
		WorldGrid.BIOME_GRASS:
			return { "gram_positive": true, "metabolism": 0.025, "move_speed": 35.0 }
		WorldGrid.BIOME_WOOD:
			return { "gram_positive": true, "metabolism": 0.018, "division_threshold": 0.9 }
		_:
			return {}


func _random_spawn_pos() -> Vector2:
	var angle := randf() * TAU
	var dist := sqrt(randf()) * SPAWN_RADIUS
	return _camera_world_pos + Vector2(cos(angle), sin(angle)) * dist
