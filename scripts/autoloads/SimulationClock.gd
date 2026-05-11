extends Node

signal tick_processed(tick_count: int)
signal speed_changed(new_speed: float)
signal pause_toggled(is_paused: bool)

# 1 tick = 1 sim minute
const TICKS_PER_HOUR:  int = 60
const TICKS_PER_DAY:   int = 1440    # 24 * 60
const TICKS_PER_MONTH: int = 43200   # 30 days
const TICKS_PER_YEAR:  int = 518400  # 12 months

# Speed presets — each traverses ~1 real second per named unit at target rate
# multiplier = desired_ticks_per_real_second / tick_rate
# e.g. "1j/s" = 1440 ticks/s → multiplier = 1440 / 10 = 144
# réel = 1 sim-seconde par seconde réelle → 1 tick toutes les 60s → mult = 1/(10×60)
const SPEED_PRESETS: Array[float]  = [0.00167, 0.5,  1.0,  6.0,    144.0,   1008.0,    4320.0,    51840.0]
const SPEED_PRESET_LABELS: Array[String] = ["réel", "x½", "x1", "1h/s", "1j/s", "1sem/s", "1mois/s", "1an/s"]

const MIN_SPEED: float = 0.00167
const MAX_SPEED: float = 51840.0

var tick_rate: float = 10.0
var speed_multiplier: float = 1.0
var paused: bool = false
var tick_count: int = 0
var elapsed_sim_time: float = 0.0

var _accumulator: float = 0.0
var _speed_preset_index: int = 2  # default x1


func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta * speed_multiplier
	var tick_interval: float = 1.0 / tick_rate
	var max_ticks: int = _max_ticks_per_frame()
	var ticks_this_frame: int = 0
	while _accumulator >= tick_interval and ticks_this_frame < max_ticks:
		_accumulator -= tick_interval
		_advance_tick()
		ticks_this_frame += 1
	if _accumulator > tick_interval * max_ticks:
		_accumulator = 0.0


func _advance_tick() -> void:
	tick_count += 1
	elapsed_sim_time += 1.0 / tick_rate
	tick_processed.emit(tick_count)


# Scale max ticks per frame with speed — capped at 200 to avoid CPU spiral
func _max_ticks_per_frame() -> int:
	return clampi(int(speed_multiplier * 0.5), 4, 200)


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


func get_speed_label() -> String:
	return SPEED_PRESET_LABELS[_speed_preset_index]


# Calendar helpers
func get_calendar() -> Dictionary:
	var t: int = tick_count
	var minute: int = t % 60
	var hour: int   = (t / 60) % 24
	var day: int    = (t / TICKS_PER_DAY) % 30 + 1
	var month: int  = (t / TICKS_PER_MONTH) % 12 + 1
	var year: int   = t / TICKS_PER_YEAR + 1
	return { "minute": minute, "hour": hour, "day": day, "month": month, "year": year }


func format_date_short() -> String:
	var c: Dictionary = get_calendar()
	return "A%d M%02d J%02d  %02dh%02d" % [c.year, c.month, c.day, c.hour, c.minute]


func format_date_long() -> String:
	var c: Dictionary = get_calendar()
	return "Année %d — Mois %d — Jour %d" % [c.year, c.month, c.day]
