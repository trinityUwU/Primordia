extends Control

@onready var _label: Label = $Panel/VBox/Label

var _camera: Camera2D
var _zoom_level: int = 0
var _render_fps_samples: Array[float] = []


func _ready() -> void:
	visible = false
	await get_tree().process_frame
	_camera = get_tree().get_first_node_in_group("main_camera")


func _process(delta: float) -> void:
	if not visible:
		return
	_render_fps_samples.append(1.0 / delta if delta > 0.0 else 0.0)
	if _render_fps_samples.size() > 30:
		_render_fps_samples.pop_front()
	_update_label()


func _update_label() -> void:
	var render_fps: float = _avg_fps()
	var tick_rate_real: float = SimulationClock.get_sim_fps()
	var mouse_grid: Vector2i = _get_mouse_grid_coords()
	var counts: Dictionary = _count_by_type()
	var heatmap_node: Node = get_tree().get_first_node_in_group("heatmap_overlay")
	var heatmap_str: String = ""
	if heatmap_node:
		var hm := heatmap_node as Node
		var lbl: Array[String] = ["OFF", "Nutrients", "Toxins", "Temperature"]
		var m: int = hm.get("mode") if hm.get("mode") != null else 0
		if m != 0:
			heatmap_str = "\nHeatmap: " + lbl[m]
	_label.text = (
		"FPS: %d\nTick rate: %.1f/s\nBacteria: %d\nVirus: %d\nProtozoa: %d\nPlants: %d\nFungi: %d\nTotal: %d\nVirtual: %d\nZoom: %d\nGrid: %d,%d%s" % [
			int(render_fps),
			tick_rate_real,
			counts.get(AgentPool.TYPE_BACTERIUM, 0),
			counts.get(AgentPool.TYPE_VIRUS, 0),
			counts.get(AgentPool.TYPE_PROTOZOA, 0),
			counts.get(AgentPool.TYPE_PLANT, 0),
			counts.get(AgentPool.TYPE_FUNGI, 0),
			AgentPool._alive_count,
			PopulationLOD.get_total_aggregate_population(),
			_zoom_level,
			mouse_grid.x,
			mouse_grid.y,
			heatmap_str,
		]
	)


func _count_by_type() -> Dictionary:
	var counts: Dictionary = {}
	for i in AgentPool.count:
		if AgentPool.flags[i] & AgentPool.FLAG_ALIVE == 0:
			continue
		var t: int = AgentPool.agent_type[i]
		counts[t] = counts.get(t, 0) + 1
	return counts


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
