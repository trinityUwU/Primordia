extends Node

signal tick_processed(tick_count: int)
signal speed_changed(new_speed: float)
signal pause_toggled(is_paused: bool)

const SPEED_PRESETS: Array[float] = [0.1, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0]
const MIN_SPEED: float = 0.1
const MAX_SPEED: float = 32.0

var tick_rate: float = 10.0
var speed_multiplier: float = 1.0
var paused: bool = false
var tick_count: int = 0
var elapsed_sim_time: float = 0.0

var _accumulator: float = 0.0
var _speed_preset_index: int = 3


func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta * speed_multiplier
	var tick_interval: float = 1.0 / tick_rate
	while _accumulator >= tick_interval:
		_accumulator -= tick_interval
		_advance_tick()


func _advance_tick() -> void:
	tick_count += 1
	elapsed_sim_time += 1.0 / tick_rate
	tick_processed.emit(tick_count)


func set_speed(s: float) -> void:
	speed_multiplier = clampf(s, MIN_SPEED, MAX_SPEED)
	_accumulator = 0.0
	speed_changed.emit(speed_multiplier)


func toggle_pause() -> void:
	paused = !paused
	_accumulator = 0.0
	pause_toggled.emit(paused)


func step_once() -> void:
	_advance_tick()


func get_sim_fps() -> float:
	return tick_rate * speed_multiplier


func set_speed_preset_next() -> void:
	_speed_preset_index = mini(_speed_preset_index + 1, SPEED_PRESETS.size() - 1)
	set_speed(SPEED_PRESETS[_speed_preset_index])


func set_speed_preset_prev() -> void:
	_speed_preset_index = maxi(_speed_preset_index - 1, 0)
	set_speed(SPEED_PRESETS[_speed_preset_index])


func get_speed_preset_index() -> int:
	return _speed_preset_index
