extends Node

const ACTIVE_SPAWN_RADIUS: float = 2500.0
const TARGET_DENSITY: float = 0.02
const SPAWN_PER_TICK: int = 5

var _camera_world_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)
	call_deferred("_find_agent_layer")


func _find_agent_layer() -> void:
	# Ensure PopulationManager has its agent layer resolved before we spawn
	pass


func _on_tick(_tick: int) -> void:
	_update_camera_pos()
	WorldGrid.update_active_chunks(_camera_world_pos, ACTIVE_SPAWN_RADIUS)
	_maybe_spawn()


func _update_camera_pos() -> void:
	var cam: Node = get_tree().get_first_node_in_group("main_camera")
	if cam != null:
		_camera_world_pos = (cam as Node2D).global_position


func _maybe_spawn() -> void:
	var active_cells: int = _count_active_cells()
	var target_count: int = int(active_cells * TARGET_DENSITY)
	var current_count: int = PopulationManager.get_population_count()
	if current_count >= target_count:
		return
	var to_spawn: int = mini(SPAWN_PER_TICK, target_count - current_count)
	for i in to_spawn:
		var pos: Vector2 = _random_spawn_pos()
		PopulationManager.spawn_bacterium(pos)


func _count_active_cells() -> int:
	return WorldGrid._active_chunks.size() * WorldGrid.CHUNK_SIZE * WorldGrid.CHUNK_SIZE


func _random_spawn_pos() -> Vector2:
	var half: float = ACTIVE_SPAWN_RADIUS
	return _camera_world_pos + Vector2(
		randf_range(-half, half),
		randf_range(-half, half)
	)
