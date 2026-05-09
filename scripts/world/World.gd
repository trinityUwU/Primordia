extends Node2D

signal zoom_level_changed(level: int)

var zoom_level: int = 0
var _debug_visible: bool = false
var _grid_visible: bool = false

@onready var _camera: Camera2D = $Camera2D
@onready var _grid_renderer: Node2D = $GridRenderer
@onready var _debug_overlay: Control = $UILayer/DebugOverlay
@onready var _territory_overlay: Node2D = $TerritoryOverlay
@onready var _territory_info: Control = $UILayer/TerritoryInfoPanel


func _ready() -> void:
	_grid_renderer.visible = false
	_debug_overlay.visible = false
	_camera.zoom_level_changed.connect(_on_zoom_level_changed)
	_territory_overlay.territory_clicked.connect(_on_territory_clicked)


func _on_territory_clicked(chunk_coord: Vector2i, agents: Array[int]) -> void:
	var cull_rect: Rect2 = _get_camera_world_rect()
	_territory_info.show_for_chunk(chunk_coord, agents, cull_rect)


func _get_camera_world_rect() -> Rect2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / _camera.zoom
	return Rect2(_camera.global_position - half, half * 2.0)


func _on_zoom_level_changed(level: int) -> void:
	zoom_level = level
	_debug_overlay.set_zoom_level(level)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				SimulationClock.toggle_pause()
			KEY_EQUAL, KEY_KP_ADD:
				SimulationClock.set_speed_preset_next()
			KEY_MINUS, KEY_KP_SUBTRACT:
				SimulationClock.set_speed_preset_prev()
			KEY_F1:
				_toggle_debug_overlay()
			KEY_G:
				_toggle_grid()


func _toggle_debug_overlay() -> void:
	_debug_visible = !_debug_visible
	_debug_overlay.visible = _debug_visible


func _toggle_grid() -> void:
	_grid_visible = !_grid_visible
	_grid_renderer.visible = _grid_visible


func set_zoom_level(level: int) -> void:
	zoom_level = level
	zoom_level_changed.emit(zoom_level)
