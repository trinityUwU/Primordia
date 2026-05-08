extends Control

@onready var _btn_pause: Button = $HBox/BtnPause
@onready var _btn_slower: Button = $HBox/BtnSlower
@onready var _btn_faster: Button = $HBox/BtnFaster
@onready var _label_speed: Label = $HBox/LabelSpeed
@onready var _label_tick: Label = $HBox/LabelTick
@onready var _label_time: Label = $HBox/LabelTime


func _ready() -> void:
	SimulationClock.tick_processed.connect(_on_tick)
	SimulationClock.speed_changed.connect(_on_speed_changed)
	SimulationClock.pause_toggled.connect(_on_pause_toggled)
	_btn_pause.pressed.connect(_on_pause_pressed)
	_btn_slower.pressed.connect(_on_slower_pressed)
	_btn_faster.pressed.connect(_on_faster_pressed)
	_refresh_speed_label()
	_refresh_pause_label()


func _on_tick(_tick: int) -> void:
	_label_tick.text = "Tick: %d" % SimulationClock.tick_count
	_label_time.text = "T: %s" % _format_sim_time(SimulationClock.elapsed_sim_time)


func _on_speed_changed(_new_speed: float) -> void:
	_refresh_speed_label()


func _on_pause_toggled(_is_paused: bool) -> void:
	_refresh_pause_label()


func _on_pause_pressed() -> void:
	SimulationClock.toggle_pause()


func _on_slower_pressed() -> void:
	SimulationClock.set_speed_preset_prev()


func _on_faster_pressed() -> void:
	SimulationClock.set_speed_preset_next()


func _refresh_speed_label() -> void:
	_label_speed.text = "x%.2f" % SimulationClock.speed_multiplier


func _refresh_pause_label() -> void:
	_btn_pause.text = "▶" if SimulationClock.paused else "⏸"


func _format_sim_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]
