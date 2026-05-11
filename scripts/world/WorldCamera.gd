extends Camera2D

signal zoom_level_changed(level: int)
signal zoom_changed(zoom_value: float)

# 1 world unit = 1 μm
# CELL_SIZE = 8 wu = 8 μm per cell
# Chunk = 256 cells = 2048 μm ≈ 2mm

const ZOOM_SPEED: float = 8.0
const ZOOM_STEP: float = 1.20
const PAN_BUTTON: int = MOUSE_BUTTON_MIDDLE
const PAN_SPEED: float = 400.0

# Named snap levels: zoom value = screen_pixels / world_units displayed
# At base resolution (1920px wide):
#   zoom 4.0  → viewport = 480 μm   (bacteria scale)
#   zoom 1.0  → viewport = 1920 μm  (cell scale ~2mm)
#   zoom 0.05 → viewport = 38mm     (insect scale)
#   zoom 0.002→ viewport = ~1m      (small animal)
#   zoom 0.0002→ viewport = ~10m    (dinosaur scale)
const SNAP_LEVELS: Array[float]    = [0.0002,  0.002,   0.05,   1.0,    4.0  ]
const SNAP_LABELS: Array[String]   = ["Paysage","Macro","Méso","Cellul.","Micro"]
const ZOOM_MIN: float = 0.00005
const ZOOM_MAX: float = 8.0

var _target_zoom: float = 1.0
var _current_level: int = 3
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_camera: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("main_camera")
	await get_tree().process_frame
	_setup_zoom()


func _setup_zoom() -> void:
	var base: float = get_viewport().get_visible_rect().size.x / 1920.0
	_target_zoom = base
	zoom = Vector2(base, base)
	_update_snap_level()


func _process(delta: float) -> void:
	var current_zoom: float = zoom.x
	var new_zoom: float = maxf(lerpf(current_zoom, _target_zoom, ZOOM_SPEED * delta), ZOOM_MIN)
	# Snap to target when close enough to avoid infinite lerp drift
	if abs(new_zoom - _target_zoom) < _target_zoom * 0.0005:
		new_zoom = _target_zoom
	if new_zoom != zoom.x:
		zoom = Vector2(new_zoom, new_zoom)
		zoom_changed.emit(new_zoom)
	_handle_wasd(delta)


func _handle_wasd(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
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
		MOUSE_BUTTON_WHEEL_UP:   _zoom_in_smooth()
		MOUSE_BUTTON_WHEEL_DOWN: _zoom_out_smooth()
		PAN_BUTTON:
			_is_panning = event.pressed
			if event.pressed:
				_pan_start_mouse = event.global_position
				_pan_start_camera = global_position


func _handle_pan(event: InputEventMouseMotion) -> void:
	global_position = _pan_start_camera - (event.global_position - _pan_start_mouse) / zoom.x


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1: _snap_to_level(0)
		KEY_2: _snap_to_level(1)
		KEY_3: _snap_to_level(2)
		KEY_4: _snap_to_level(3)
		KEY_5: _snap_to_level(4)


func _zoom_in_smooth() -> void:
	_target_zoom = clampf(_target_zoom * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	_update_snap_level()


func _zoom_out_smooth() -> void:
	_target_zoom = clampf(_target_zoom / ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	_update_snap_level()


func _snap_to_level(level: int) -> void:
	_current_level = clampi(level, 0, SNAP_LEVELS.size() - 1)
	_target_zoom = SNAP_LEVELS[_current_level]
	zoom_level_changed.emit(_current_level)


func _update_snap_level() -> void:
	var prev: int = _current_level
	var best: int = 0
	var best_dist: float = INF
	for i in SNAP_LEVELS.size():
		var d: float = abs(log(_target_zoom) - log(SNAP_LEVELS[i]))
		if d < best_dist:
			best_dist = d
			best = i
	_current_level = best
	if _current_level != prev:
		zoom_level_changed.emit(_current_level)


# Returns world units per screen pixel at current zoom
func get_world_units_per_pixel() -> float:
	return 1.0 / zoom.x


# Returns the scale context label for current zoom
func get_scale_label() -> String:
	return SNAP_LABELS[_current_level]
