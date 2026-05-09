extends Control

@onready var _label: Label = $Panel/VBox/Label

var _camera: Camera2D
var _zoom_level: int = 0
var _render_fps_samples: Array[float] = []
var _label_frame: int = 0

var _last_sample_sim_time: float = 0.0
var _births_per_sec: float = 0.0
var _deaths_per_sec: float = 0.0
var _o2_consumed_per_sec: float = 0.0
var _o2_produced_per_sec: float = 0.0


func _ready() -> void:
	visible = false
	await get_tree().process_frame
	_camera = get_tree().get_first_node_in_group("main_camera")
	SimulationClock.tick_processed.connect(_on_tick)


func _on_tick(_tick: int) -> void:
	var sim_time: float = SimulationClock.elapsed_sim_time
	var elapsed: float = sim_time - _last_sample_sim_time
	if elapsed >= 1.0:
		var factor: float = 1.0 / elapsed
		_births_per_sec = AgentPool._births_tick * factor
		_deaths_per_sec = AgentPool._deaths_tick * factor
		_o2_consumed_per_sec = AgentPool._o2_consumed_tick * factor
		_o2_produced_per_sec = AgentPool._o2_produced_tick * factor
		AgentPool._births_tick = 0
		AgentPool._deaths_tick = 0
		AgentPool._o2_consumed_tick = 0.0
		AgentPool._o2_produced_tick = 0.0
		_last_sample_sim_time = sim_time


func _process(delta: float) -> void:
	if not visible:
		return
	_render_fps_samples.append(1.0 / delta if delta > 0.0 else 0.0)
	if _render_fps_samples.size() > 30:
		_render_fps_samples.pop_front()
	_label_frame += 1
	if _label_frame >= 6:
		_label_frame = 0
		_update_label()


func _update_label() -> void:
	var fps: float = _avg_fps()
	var tick_rate: float = SimulationClock.get_sim_fps()
	var grid: Vector2i = _get_mouse_grid_coords()
	var c: PackedInt32Array = AgentPool._type_counts
	var net: float = _births_per_sec - _deaths_per_sec
	var net_s: String = ("+%.1f" % net) if net >= 0.0 else ("%.1f" % net)
	var o2_net: float = _o2_produced_per_sec - _o2_consumed_per_sec
	var o2_s: String = ("+%.3f" % o2_net) if o2_net >= 0.0 else ("%.3f" % o2_net)
	# Sample local O2 and CO2 at mouse position
	var o2_local: float = 0.21
	var co2_local: float = 0.04
	if _camera != null:
		var gx: int = int(grid.x)
		var gy: int = int(grid.y)
		o2_local = WorldGrid.get_cell_value(gx, gy, "oxygen")
		co2_local = 1.0 - o2_local

	_label.text = (
		"%d fps  %.0f t/s\n"
		+ "Bact  %5d\n"
		+ "Virus %5d\n"
		+ "Proto %5d\n"
		+ "Plant %5d\n"
		+ "Fungi %5d\n"
		+ "Live  %5d  +%d virt\n"
		+ "Net  %s/s   O2 %s/s\n"
		+ "O2 %.2f  CO2 %.2f\n"
		+ "%d,%d  z%d"
	) % [
		int(fps), tick_rate,
		c[AgentPool.TYPE_BACTERIUM],
		c[AgentPool.TYPE_VIRUS],
		c[AgentPool.TYPE_PROTOZOA],
		c[AgentPool.TYPE_PLANT],
		c[AgentPool.TYPE_FUNGI],
		AgentPool._alive_count,
		PopulationLOD.get_total_aggregate_population(),
		net_s, o2_s,
		o2_local, co2_local,
		grid.x, grid.y, _zoom_level,
	]


func _avg_fps() -> float:
	if _render_fps_samples.is_empty():
		return 0.0
	var total: float = 0.0
	for v in _render_fps_samples:
		total += v
	return total / _render_fps_samples.size()


func _get_mouse_grid_coords() -> Vector2i:
	if _camera == null:
		return Vector2i.ZERO
	var mouse_screen: Vector2 = get_viewport().get_mouse_position()
	var mouse_world: Vector2 = _camera.get_screen_center_position() + (
		(mouse_screen - get_viewport().get_visible_rect().size * 0.5) / _camera.zoom.x
	)
	return WorldGrid.world_to_grid(mouse_world)


func set_zoom_level(level: int) -> void:
	_zoom_level = level
