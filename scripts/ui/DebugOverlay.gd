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
	_label.text = (
		"FPS: %d\nTick rate: %.1f/s\nPopulation: 0\nZoom: %d\nGrid: %d,%d" % [
			int(render_fps),
			tick_rate_real,
			_zoom_level,
			mouse_grid.x,
			mouse_grid.y,
		]
	)


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
