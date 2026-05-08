extends Node

const ACTIVE_SPAWN_RADIUS: float = 1200.0  # zone active raisonnable
const MAX_AGENTS: int = 800               # cap dur global
const TARGET_DENSITY: float = 0.005       # densité très réduite
const SPAWN_PER_TICK: int = 3
const SPAWN_EVERY_N_TICKS: int = 5        # spawn pas à chaque tick

var _camera_world_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)
	call_deferred("_find_agent_layer")


func _find_agent_layer() -> void:
	# Ensure PopulationManager has its agent layer resolved before we spawn
	pass


func _on_tick(tick: int) -> void:
	_update_camera_pos()
	WorldGrid.update_active_chunks(_camera_world_pos, ACTIVE_SPAWN_RADIUS)
	if tick % SPAWN_EVERY_N_TICKS == 0:
		_maybe_spawn()


func _update_camera_pos() -> void:
	var cam: Node = get_tree().get_first_node_in_group("main_camera")
	if cam != null:
		_camera_world_pos = (cam as Node2D).global_position


func _maybe_spawn() -> void:
	var current_count: int = PopulationManager.get_population_count()
	if current_count >= MAX_AGENTS:
		return
	var active_cells: int = _count_active_cells()
	var target_count: int = mini(int(active_cells * TARGET_DENSITY), MAX_AGENTS)
	if current_count >= target_count:
		return
	var to_spawn: int = mini(SPAWN_PER_TICK, target_count - current_count)
	for i in to_spawn:
		PopulationManager.spawn_bacterium(_random_spawn_pos())


func _count_active_cells() -> int:
	return WorldGrid._active_chunks.size() * WorldGrid.CHUNK_SIZE * WorldGrid.CHUNK_SIZE


func _random_spawn_pos() -> Vector2:
	var half: float = ACTIVE_SPAWN_RADIUS
	return _camera_world_pos + Vector2(
		randf_range(-half, half),
		randf_range(-half, half)
	)
