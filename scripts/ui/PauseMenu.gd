extends CanvasLayer

const FADE_DURATION: float = 0.15

var _visible: bool = false
var _panel_origin_x: float = 0.0

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: PanelContainer = $Panel
@onready var _btn_resume: Button = $Panel/VBox/BtnResume
@onready var _btn_settings: Button = $Panel/VBox/BtnSettings
@onready var _btn_exit: Button = $Panel/VBox/BtnExit
@onready var _panel_settings: PanelContainer = $PanelSettings
@onready var _slider_autosave: HSlider = $PanelSettings/VBox/SliderAutosave
@onready var _label_interval: Label = $PanelSettings/VBox/LabelInterval
@onready var _btn_save_settings: Button = $PanelSettings/VBox/BtnSaveSettings
@onready var _btn_back_settings: Button = $PanelSettings/VBox/BtnBack
@onready var _label_autosave_status: Label = $Panel/VBox/LabelAutosaveStatus


func _ready() -> void:
	layer = 50
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_panel.modulate.a = 0.0
	_panel_settings.modulate.a = 0.0
	_panel_settings.visible = false
	visible = false

	await get_tree().process_frame
	_panel_origin_x = _panel.position.x
	_panel.pivot_offset = _panel.size / 2.0

	_btn_resume.pressed.connect(close)
	_btn_settings.pressed.connect(_open_settings)
	_btn_exit.pressed.connect(_on_exit_pressed)
	_btn_save_settings.pressed.connect(_on_save_settings)
	_btn_back_settings.pressed.connect(_close_settings)
	_slider_autosave.value_changed.connect(_on_slider_changed)

	_setup_settings_values()

	SaveManager.autosave_triggered.connect(_on_autosave)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			if _panel_settings.visible:
				_close_settings()
			elif _visible:
				close()
			else:
				open()
			get_viewport().set_input_as_handled()


func open() -> void:
	_visible = true
	visible = true
	get_tree().paused = true
	_panel.scale = Vector2(0.95, 0.95)
	_panel.modulate.a = 0.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.6), 0.18)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.18)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func close() -> void:
	_visible = false
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "scale", Vector2(0.95, 0.95), 0.14)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.14)
	tw.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), 0.14)
	tw.chain().tween_callback(func() -> void:
		visible = false
		get_tree().paused = false
	)


func _open_settings() -> void:
	_panel_settings.visible = true
	_panel_settings.modulate.a = 0.0
	var settings_origin_x: float = _panel_settings.position.x
	_panel_settings.position.x = settings_origin_x + 60.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "position:x", _panel_origin_x - 30.0, 0.18)
	tw.tween_property(_panel, "modulate:a", 0.3, 0.18)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel_settings, "position:x", settings_origin_x, 0.18)
	tw.tween_property(_panel_settings, "modulate:a", 1.0, 0.18)


func _close_settings() -> void:
	var settings_current_x: float = _panel_settings.position.x
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_panel_settings, "position:x", settings_current_x + 60.0, 0.14)
	tw.tween_property(_panel_settings, "modulate:a", 0.0, 0.14)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "position:x", _panel_origin_x, 0.18)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tw.chain().tween_callback(func() -> void: _panel_settings.visible = false)


func _setup_settings_values() -> void:
	var slot_id: String = SaveManager.get_current_slot_id()
	var interval: float = 300.0
	if slot_id != "":
		var saves: Array[Dictionary] = SaveManager.list_saves()
		for s in saves:
			if s["id"] == slot_id:
				interval = float(s.get("autosave_interval", 300))
				break
	_slider_autosave.min_value = 5.0
	_slider_autosave.max_value = 3600.0
	_slider_autosave.value = interval
	_update_interval_label(interval)


func _on_slider_changed(value: float) -> void:
	_update_interval_label(value)


func _update_interval_label(value: float) -> void:
	var secs: int = int(value)
	if secs < 60:
		_label_interval.text = "%d sec" % secs
	elif secs < 3600:
		_label_interval.text = "%d min %d sec" % [secs / 60, secs % 60]
	else:
		_label_interval.text = "1 hour"


func _on_save_settings() -> void:
	var interval: int = int(_slider_autosave.value)
	var slot_id: String = SaveManager.get_current_slot_id()
	if slot_id != "":
		SaveManager.set_slot_autosave_interval(slot_id, interval)
	_btn_save_settings.text = "Saved ✓"
	await get_tree().create_timer(1.2).timeout
	_btn_save_settings.text = "Save Settings"


func _on_exit_pressed() -> void:
	var slot_id: String = SaveManager.get_current_slot_id()
	if slot_id != "":
		SaveManager.save_current(slot_id)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_autosave(slot_id: String) -> void:
	_label_autosave_status.text = "● Autosaved"
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_label_autosave_status, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func() -> void:
		_label_autosave_status.modulate.a = 1.0
		_label_autosave_status.text = ""
	)
