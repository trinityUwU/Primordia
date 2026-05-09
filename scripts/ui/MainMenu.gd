extends Control

const WORLD_SCENE: String = "res://scenes/World.tscn"
const PANEL_SLIDE_DURATION: float = 0.28
const FADE_DURATION: float = 0.3
const COLOR_ACCENT: Color = Color(0.31, 0.76, 0.97, 1.0)
const COLOR_BORDER: Color = Color(0.2, 0.2, 0.21, 1.0)
const COLOR_BORDER_HOVER: Color = Color(0.31, 0.76, 0.97, 1.0)

@onready var _root_fade: ColorRect = $RootFade
@onready var _btn_new_game: Button = $Center/VBox/BtnNewGame
@onready var _btn_load_game: Button = $Center/VBox/BtnLoadGame
@onready var _btn_settings: Button = $Center/VBox/BtnSettings
@onready var _btn_quit: Button = $Center/VBox/BtnQuit
@onready var _panel_new: Control = $PanelNewGame
@onready var _panel_load: Control = $PanelLoad
@onready var _panel_settings: Control = $PanelSettings
@onready var _input_save_name: LineEdit = $PanelNewGame/VBox/InputSaveName
@onready var _btn_create: Button = $PanelNewGame/VBox/BtnCreate
@onready var _btn_cancel_new: Button = $PanelNewGame/VBox/BtnCancel
@onready var _saves_list: VBoxContainer = $PanelLoad/VBoxOuter/ScrollContainer/SavesList
@onready var _no_saves_label: Label = $PanelLoad/VBoxOuter/ScrollContainer/NoSavesLabel
@onready var _btn_back_load: Button = $PanelLoad/VBoxOuter/BtnBack
@onready var _slider_autosave: HSlider = $PanelSettings/VBox/SliderAutosave
@onready var _label_interval: Label = $PanelSettings/VBox/LabelInterval
@onready var _btn_save_settings: Button = $PanelSettings/VBox/BtnSaveSettings
@onready var _btn_back_settings: Button = $PanelSettings/VBox/BtnBack
@onready var _center: Control = $Center
@onready var _bg_rect: ColorRect = $BgRect
@onready var _noise_overlay: ColorRect = $NoiseOverlay
@onready var _title: Label = $Center/VBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle

var _active_panel: Control = null
var _pending_slot_id: String = ""
var _panel_targets: Dictionary = {}  # panel → target_x when open


func _ready() -> void:
	_apply_initial_settings()
	modulate.a = 0.0
	await get_tree().process_frame
	# Store natural positions before hiding
	for p: Control in [_panel_new, _panel_load, _panel_settings]:
		_panel_targets[p] = p.position.x
	_hide_panels_instant()
	_animate_intro()
	_connect_signals()


func _animate_intro() -> void:
	_bg_rect.modulate.a = 0.0
	_noise_overlay.modulate.a = 0.0
	var tw_bg: Tween = create_tween().set_parallel(true)
	tw_bg.set_ease(Tween.EASE_OUT)
	tw_bg.tween_property(_bg_rect, "modulate:a", 1.0, 0.4)
	tw_bg.tween_property(_noise_overlay, "modulate:a", 1.0, 0.4)
	modulate.a = 1.0
	await tw_bg.finished
	_animate_menu_stagger()


func _animate_menu_stagger() -> void:
	var delay: float = 0.0
	_animate_slide_y(_title, delay)
	delay += 0.06
	_animate_slide_y(_subtitle, delay)
	delay += 0.06
	for btn: Button in [_btn_new_game, _btn_load_game, _btn_settings, _btn_quit]:
		_animate_slide_x(btn, delay)
		delay += 0.06


func _animate_slide_y(node: Control, delay: float) -> void:
	var origin_y: float = node.position.y
	node.modulate.a = 0.0
	node.position.y = origin_y + 20.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUART)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, 0.35).set_delay(delay)
	tw.tween_property(node, "position:y", origin_y, 0.35).set_delay(delay)


func _animate_slide_x(node: Control, delay: float) -> void:
	var origin_x: float = node.position.x
	node.modulate.a = 0.0
	node.position.x = origin_x - 15.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUART)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, 0.28).set_delay(delay)
	tw.tween_property(node, "position:x", origin_x, 0.28).set_delay(delay)


func _connect_signals() -> void:
	_btn_new_game.pressed.connect(func() -> void: _open_panel(_panel_new))
	_btn_load_game.pressed.connect(_on_load_game_pressed)
	_btn_settings.pressed.connect(func() -> void: _open_panel(_panel_settings))
	_btn_quit.pressed.connect(func() -> void: get_tree().quit())
	_btn_create.pressed.connect(_on_create_pressed)
	_btn_cancel_new.pressed.connect(func() -> void: _close_panel(_panel_new))
	_btn_back_load.pressed.connect(func() -> void: _close_panel(_panel_load))
	_btn_save_settings.pressed.connect(_on_save_settings_pressed)
	_btn_back_settings.pressed.connect(func() -> void: _close_panel(_panel_settings))
	_slider_autosave.value_changed.connect(_on_slider_changed)
	for btn: Button in [_btn_new_game, _btn_load_game, _btn_settings]:
		_connect_hover(btn)


func _connect_hover(btn: Button) -> void:
	btn.mouse_entered.connect(func() -> void:
		var tw: Tween = create_tween().set_parallel(true)
		tw.set_trans(Tween.TRANS_QUART)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		tw.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.12)
	)
	btn.mouse_exited.connect(func() -> void:
		var tw: Tween = create_tween().set_parallel(true)
		tw.set_trans(Tween.TRANS_QUART)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)


func _hide_panels_instant() -> void:
	for panel: Control in [_panel_new, _panel_load, _panel_settings]:
		panel.position.x = get_viewport_rect().size.x + 40.0
		panel.visible = false


func _apply_initial_settings() -> void:
	var settings: Dictionary = SaveManager.get_settings()
	var interval: float = float(settings.get("default_autosave_interval", 300))
	_slider_autosave.min_value = 5.0
	_slider_autosave.max_value = 3600.0
	_slider_autosave.step = 1.0
	_slider_autosave.value = interval
	_update_interval_label(interval)


# ── Panel transitions ─────────────────────────────────────────────────────────

func _open_panel(panel: Control) -> void:
	if _active_panel != null and _active_panel != panel:
		_close_panel(_active_panel)
	_active_panel = panel
	panel.visible = true
	panel.modulate.a = 0.0
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var target_x: float = _panel_targets.get(panel, panel.position.x)
	panel.position.x = get_viewport_rect().size.x + 40.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUINT)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_center, "modulate:a", 0.4, 0.2)
	tw.tween_property(panel, "position:x", target_x, PANEL_SLIDE_DURATION)
	tw.tween_property(panel, "modulate:a", 1.0, PANEL_SLIDE_DURATION)


func _close_panel(panel: Control) -> void:
	if _active_panel == panel:
		_active_panel = null
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	var tw: Tween = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUINT)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_center, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "position:x", get_viewport_rect().size.x + 40.0, 0.22)
	tw.tween_property(panel, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(func() -> void: panel.visible = false)


# ── New Game ──────────────────────────────────────────────────────────────────

func _on_create_pressed() -> void:
	var name_text: String = _input_save_name.text.strip_edges()
	if name_text == "":
		name_text = "My World"
	var slot_id: String = SaveManager.new_save(name_text)
	var ok: bool = SaveManager.load_save(slot_id)
	if not ok:
		push_error("MainMenu: load_save failed after new_save")
		return
	_pending_slot_id = slot_id
	_transition_to_world()


# ── Load Game ─────────────────────────────────────────────────────────────────

func _on_load_game_pressed() -> void:
	_populate_saves_list()
	_open_panel(_panel_load)


func _populate_saves_list() -> void:
	for child in _saves_list.get_children():
		child.queue_free()
	await get_tree().process_frame  # wait for queue_free to execute
	var saves: Array[Dictionary] = SaveManager.list_saves()
	print("SaveManager.list_saves() returned: ", saves.size(), " saves")
	_no_saves_label.visible = saves.is_empty()
	for save: Dictionary in saves:
		_saves_list.add_child(_build_save_row(save))


func _build_save_row(save: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_name: Label = Label.new()
	lbl_name.text = save.get("name", "—")
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93, 1.0))
	var lbl_meta: Label = Label.new()
	lbl_meta.text = "%s  ·  %s" % [
		save.get("last_saved", ""),
		_format_playtime(save.get("playtime", 0))
	]
	lbl_meta.add_theme_font_size_override("font_size", 11)
	lbl_meta.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
	info.add_child(lbl_name)
	info.add_child(lbl_meta)
	var btn_load: Button = Button.new()
	btn_load.text = "Load"
	btn_load.flat = false
	_style_button_secondary(btn_load)
	var slot_id: String = save.get("id", "")
	btn_load.pressed.connect(func() -> void: _on_slot_load_pressed(slot_id))
	var btn_del: Button = Button.new()
	btn_del.text = "×"
	btn_del.flat = true
	btn_del.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 1.0))
	btn_del.pressed.connect(func() -> void: _on_slot_delete_pressed(slot_id, row))
	row.add_child(info)
	row.add_child(btn_load)
	row.add_child(btn_del)
	return row


func _on_slot_load_pressed(slot_id: String) -> void:
	var ok: bool = SaveManager.load_save(slot_id)
	if not ok:
		return
	_pending_slot_id = slot_id
	_transition_to_world()


func _on_slot_delete_pressed(slot_id: String, row: Control) -> void:
	SaveManager.delete_save(slot_id)
	row.queue_free()
	var remaining: int = _saves_list.get_child_count() - 1
	_no_saves_label.visible = remaining <= 0


# ── Settings ──────────────────────────────────────────────────────────────────

func _on_slider_changed(value: float) -> void:
	_update_interval_label(value)


func _update_interval_label(value: float) -> void:
	var sec: int = int(value)
	if sec < 60:
		_label_interval.text = "%d sec" % sec
	elif sec < 3600:
		var m: int = sec / 60
		var s: int = sec % 60
		if s == 0:
			_label_interval.text = "%d min" % m
		else:
			_label_interval.text = "%d min %d sec" % [m, s]
	else:
		_label_interval.text = "1 hour"


func _on_save_settings_pressed() -> void:
	SaveManager.save_settings({ "default_autosave_interval": int(_slider_autosave.value) })
	# Visual feedback without closing the panel
	_btn_save_settings.text = "Saved ✓"
	await get_tree().create_timer(1.2).timeout
	_btn_save_settings.text = "Save Settings"


# ── Scene transition ──────────────────────────────────────────────────────────

func _transition_to_world() -> void:
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tw: Tween = create_tween()
	tw.tween_property(flash, "color:a", 0.15, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "color:a", 0.0, 0.1).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(WORLD_SCENE))


# ── Style helpers ─────────────────────────────────────────────────────────────

func _style_button_secondary(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))


func _format_playtime(seconds: int) -> String:
	var h: int = seconds / 3600
	var m: int = (seconds % 3600) / 60
	var s: int = seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
