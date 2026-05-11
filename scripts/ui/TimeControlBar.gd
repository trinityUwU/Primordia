extends Control

@onready var _btn_pause: Button = $Panel/HBox/BtnPause
@onready var _btn_slower: Button = $Panel/HBox/BtnSlower
@onready var _btn_faster: Button = $Panel/HBox/BtnFaster
@onready var _label_speed: Label = $Panel/HBox/LabelSpeed
@onready var _label_tick: Label = $Panel/HBox/LabelTick
@onready var _label_time: Label = $Panel/HBox/LabelTime


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
	_label_tick.text = ""
	_label_time.text = "%s  (T%d)" % [SimulationClock.format_date_short(), SimulationClock.tick_count]


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
	_label_speed.text = SimulationClock.get_speed_label()


func _refresh_pause_label() -> void:
	_btn_pause.text = "▶" if SimulationClock.paused else "⏸"


