extends Camera2D

signal zoom_level_changed(level: int)

var ZOOM_LEVELS: Array[float] = [0.5, 1.5, 4.0]
const ZOOM_SPEED: float = 8.0
const PAN_BUTTON: int = MOUSE_BUTTON_MIDDLE
const PAN_SPEED: float = 400.0

var _target_zoom: float = 1.5
var _current_level: int = 1
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_camera: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("main_camera")
	await get_tree().process_frame
	_fit_to_world()


func _fit_to_world() -> void:
	var world_w: float = WorldGrid.GRID_WIDTH * WorldGrid.CELL_SIZE
	var world_h: float = WorldGrid.GRID_HEIGHT * WorldGrid.CELL_SIZE
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var fit_zoom: float = minf(vp.x / world_w, vp.y / world_h)
	ZOOM_LEVELS[0] = fit_zoom * 0.4
	ZOOM_LEVELS[1] = fit_zoom
	ZOOM_LEVELS[2] = fit_zoom * 4.0
	_target_zoom = fit_zoom
	zoom = Vector2(fit_zoom, fit_zoom)
	global_position = Vector2(world_w * 0.5, world_h * 0.5)


func _process(delta: float) -> void:
	var current_zoom: float = zoom.x
	var new_zoom: float = lerpf(current_zoom, _target_zoom, ZOOM_SPEED * delta)
	zoom = Vector2(new_zoom, new_zoom)
	_handle_wasd(delta)
	_clamp_position()


func _handle_wasd(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * PAN_SPEED * delta / zoom.x


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _is_panning:
		_handle_pan(event as InputEventMouseMotion)
	elif event is InputEventKey and event.pressed:
		_handle_key(event as InputEventKey)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_zoom_in_smooth()
		MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out_smooth()
		PAN_BUTTON:
			if event.pressed:
				_is_panning = true
				_pan_start_mouse = event.global_position
				_pan_start_camera = global_position
			else:
				_is_panning = false


func _handle_pan(event: InputEventMouseMotion) -> void:
	var delta_mouse: Vector2 = event.global_position - _pan_start_mouse
	global_position = _pan_start_camera - delta_mouse / zoom.x
	_clamp_position()


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1:
			_snap_to_level(0)
		KEY_2:
			_snap_to_level(1)
		KEY_3:
			_snap_to_level(2)


func _zoom_in_smooth() -> void:
	_target_zoom = clampf(_target_zoom * 1.15, ZOOM_LEVELS[0], ZOOM_LEVELS[2])
	_update_zoom_level()


func _zoom_out_smooth() -> void:
	_target_zoom = clampf(_target_zoom / 1.15, ZOOM_LEVELS[0], ZOOM_LEVELS[2])
	_update_zoom_level()


func _snap_to_level(level: int) -> void:
	_current_level = clampi(level, 0, ZOOM_LEVELS.size() - 1)
	_target_zoom = ZOOM_LEVELS[_current_level]
	zoom_level_changed.emit(_current_level)


func _update_zoom_level() -> void:
	var prev_level: int = _current_level
	if _target_zoom <= ZOOM_LEVELS[0] * 1.2:
		_current_level = 0
	elif _target_zoom >= ZOOM_LEVELS[2] * 0.8:
		_current_level = 2
	else:
		_current_level = 1
	if _current_level != prev_level:
		zoom_level_changed.emit(_current_level)


func _clamp_position() -> void:
	var world_width: float = WorldGrid.GRID_WIDTH * WorldGrid.CELL_SIZE
	var world_height: float = WorldGrid.GRID_HEIGHT * WorldGrid.CELL_SIZE
	global_position.x = clampf(global_position.x, 0.0, world_width)
	global_position.y = clampf(global_position.y, 0.0, world_height)
