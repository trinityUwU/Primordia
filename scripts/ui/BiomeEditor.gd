extends Control

const BIOME_NAMES: Array[String] = ["Water", "Earth", "Grass", "Wood", "Rock"]
const BIOME_COLORS: Array[Color] = [
	Color(0.08, 0.18, 0.38),
	Color(0.32, 0.22, 0.14),
	Color(0.22, 0.42, 0.18),
	Color(0.10, 0.25, 0.10),
	Color(0.38, 0.36, 0.34),
]

var active: bool = false
var selected_biome: int = 1
var _painting: bool = false
var brush_size: int = 1

var _brush_label: Label

@onready var _panel: PanelContainer = $Panel
@onready var _buttons: VBoxContainer = $Panel/VBox/Buttons


func _ready() -> void:
	_panel.visible = false
	_build_palette()
	_brush_label = Label.new()
	_brush_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel/VBox.add_child(_brush_label)
	_update_brush_label()


func _update_brush_label() -> void:
	if _brush_label:
		var w: int = brush_size * 2 - 1
		_brush_label.text = "Brush: %dx%d  [scroll]" % [w, w]


func _build_palette() -> void:
	for i in BIOME_NAMES.size():
		var btn: Button = Button.new()
		btn.text = BIOME_NAMES[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == selected_biome)
		var color: Color = BIOME_COLORS[i]
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.self_modulate = color.lightened(0.1)
		var idx := i
		btn.pressed.connect(func(): _select_biome(idx))
		_buttons.add_child(btn)


func _select_biome(idx: int) -> void:
	selected_biome = idx
	for i in _buttons.get_child_count():
		var btn := _buttons.get_child(i) as Button
		btn.button_pressed = (i == idx)


func toggle() -> void:
	active = !active
	_panel.visible = active
	_painting = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_E:
			toggle()
			get_viewport().set_input_as_handled()
			return

	if not active:
		return

	if event is InputEventMouseButton and active:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				brush_size = mini(brush_size + 1, 5)
				_update_brush_label()
				get_viewport().set_input_as_handled()
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				brush_size = maxi(brush_size - 1, 1)
				_update_brush_label()
				get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if _panel.get_global_rect().has_point(mb.position):
				return
			_painting = mb.pressed
			if _painting:
				_paint_at(mb.position)
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if _painting:
			_paint_at((event as InputEventMouseMotion).position)
			get_viewport().set_input_as_handled()


func _paint_at(screen_pos: Vector2) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var world_pos: Vector2 = camera.global_position + (screen_pos - vp_size * 0.5) / camera.zoom
	var center_chunk: Vector2i = WorldGrid.world_to_chunk(world_pos)
	var radius: int = brush_size - 1
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			WorldGrid.set_chunk_biome(center_chunk + Vector2i(dx, dy), selected_biome)
