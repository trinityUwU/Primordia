extends Control

@onready var _label: Label = $Panel/VBox/Label

var _camera: Camera2D
var _zoom_level: int = 0
var _render_fps_samples: Array[float] = []
var _label_frame: int = 0

# Per-second metrics (sampled every second of sim time)
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
	var render_fps: float = _avg_fps()
	var tick_rate_real: float = SimulationClock.get_sim_fps()
	var mouse_grid: Vector2i = _get_mouse_grid_coords()
	var counts: PackedInt32Array = AgentPool._type_counts
	var heatmap_node: Node = get_tree().get_first_node_in_group("heatmap_overlay")
	var heatmap_str: String = ""
	if heatmap_node:
		var hm := heatmap_node as Node
		var lbl: Array[String] = ["OFF", "Nutrients", "Toxins", "Temperature"]
		var m: int = hm.get("mode") if hm.get("mode") != null else 0
		if m != 0:
			heatmap_str = "\nHeatmap: " + lbl[m]
	var net: float = _births_per_sec - _deaths_per_sec
	var net_str: String = ("+%.1f" % net) if net >= 0.0 else ("%.1f" % net)
	_label.text = (
		"FPS: %d  Tick: %.1f/s\n"
		+ "─── Population ───\n"
		+ "Bacteria: %d\nVirus: %d\nProtozoa: %d\nPlants: %d\nFungi: %d\n"
		+ "Total: %d  Virtual: %d\n"
		+ "─── Flux /sec ───\n"
		+ "Births: +%.1f  Deaths: -%.1f\n"
		+ "Net: %s\n"
		+ "─── O2 /sec ─────\n"
		+ "Consumed: -%.4f\n"
		+ "Produced: +%.4f\n"
		+ "Balance: %s\n"
		+ "─── Env ──────────\n"
		+ "Zoom: %d  Grid: %d,%d%s"
	) % [
		int(render_fps), tick_rate_real,
		counts[AgentPool.TYPE_BACTERIUM],
		counts[AgentPool.TYPE_VIRUS],
		counts[AgentPool.TYPE_PROTOZOA],
		counts[AgentPool.TYPE_PLANT],
		counts[AgentPool.TYPE_FUNGI],
		AgentPool._alive_count,
		PopulationLOD.get_total_aggregate_population(),
		_births_per_sec, _deaths_per_sec,
		net_str,
		_o2_consumed_per_sec,
		_o2_produced_per_sec,
		("+%.4f" % (_o2_produced_per_sec - _o2_consumed_per_sec)) if (_o2_produced_per_sec - _o2_consumed_per_sec) >= 0.0 else ("%.4f" % (_o2_produced_per_sec - _o2_consumed_per_sec)),
		_zoom_level, mouse_grid.x, mouse_grid.y,
		heatmap_str,
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
