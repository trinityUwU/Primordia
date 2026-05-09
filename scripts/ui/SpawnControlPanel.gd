extends Control

const TYPE_NAMES: Array[String] = ["Bacteria", "Virus", "Protozoa", "Plants", "Fungi"]
const TYPE_COLORS: Array[Color] = [
	Color(0.310, 0.765, 0.969, 1.0),  # #4fc3f7
	Color(0.937, 0.604, 0.604, 1.0),  # #ef9a9a
	Color(0.808, 0.576, 0.847, 1.0),  # #ce93d8
	Color(0.647, 0.839, 0.655, 1.0),  # #a5d6a7
	Color(1.000, 0.800, 0.502, 1.0),  # #ffcc80
]

const SPAWN_SETTERS: Array[StringName] = [
	&"spawn_bacteria_enabled",
	&"spawn_virus_enabled",
	&"spawn_protozoa_enabled",
	&"spawn_plant_enabled",
	&"spawn_fungi_enabled",
]

var _sim_renderer: Node = null
var _territory_overlay: Node = null
var _spawn_active: Array[bool] = [true, true, false, false, false]  # mirrors ChunkSpawner defaults
var _vis_active: Array[bool] = [true, true, true, true, true]
var _terr_active: Array[bool] = [false, false, false, false, false]

# Per-row UI refs
var _dot_btns: Array[Button] = []
var _vis_btns: Array[Button] = []
var _terr_btns: Array[Button] = []
var _count_labels: Array[Label] = []

var _frame_counter: int = 0


func _ready() -> void:
	_build_ui()
	await get_tree().process_frame
	_sim_renderer = get_tree().get_first_node_in_group("sim_renderer")
	_territory_overlay = get_tree().get_first_node_in_group("territory_overlay")


func _process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter >= 60:
		_frame_counter = 0
		_update_counts()


func _build_ui() -> void:
	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.07, 0.85)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Entities"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	for t in 5:
		vbox.add_child(_build_row(t))


func _build_row(t: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Dot — toggle spawn
	var dot: Button = Button.new()
	dot.text = "●"
	dot.flat = true
	dot.add_theme_font_size_override("font_size", 14)
	dot.add_theme_color_override("font_color", TYPE_COLORS[t])
	dot.add_theme_color_override("font_color_pressed", TYPE_COLORS[t].darkened(0.4))
	dot.toggle_mode = true
	dot.button_pressed = _spawn_active[t]
	dot.custom_minimum_size = Vector2(20, 20)
	dot.tooltip_text = "Toggle spawn"
	var ti: int = t
	dot.toggled.connect(func(pressed: bool) -> void: _on_spawn_toggled(ti, pressed))
	_dot_btns.append(dot)
	row.add_child(dot)

	# Name
	var lbl: Label = Label.new()
	lbl.text = TYPE_NAMES[t]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	# Count
	var count_lbl: Label = Label.new()
	count_lbl.text = "0"
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
	count_lbl.custom_minimum_size = Vector2(32, 0)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_labels.append(count_lbl)
	row.add_child(count_lbl)

	# Visibility icon
	var vis: Button = Button.new()
	vis.text = "◉" if _vis_active[t] else "○"
	vis.flat = true
	vis.add_theme_font_size_override("font_size", 13)
	vis.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	vis.toggle_mode = true
	vis.button_pressed = _vis_active[t]
	vis.tooltip_text = "Toggle visibility"
	vis.toggled.connect(func(pressed: bool) -> void: _on_vis_toggled(ti, pressed))
	_vis_btns.append(vis)
	row.add_child(vis)

	# Territory icon
	var terr: Button = Button.new()
	terr.text = "◈" if _terr_active[t] else "◇"
	terr.flat = true
	terr.add_theme_font_size_override("font_size", 13)
	terr.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	terr.toggle_mode = true
	terr.button_pressed = _terr_active[t]
	terr.tooltip_text = "Toggle territory"
	terr.toggled.connect(func(pressed: bool) -> void: _on_terr_toggled(ti, pressed))
	_terr_btns.append(terr)
	row.add_child(terr)

	return row


func _on_spawn_toggled(type_idx: int, pressed: bool) -> void:
	_spawn_active[type_idx] = pressed
	ChunkSpawner.set(SPAWN_SETTERS[type_idx], pressed)
	_dot_btns[type_idx].add_theme_color_override(
		"font_color",
		TYPE_COLORS[type_idx] if pressed else TYPE_COLORS[type_idx].darkened(0.5)
	)


func _on_vis_toggled(type_idx: int, pressed: bool) -> void:
	_vis_active[type_idx] = pressed
	_vis_btns[type_idx].text = "◉" if pressed else "○"
	if _sim_renderer == null:
		_sim_renderer = get_tree().get_first_node_in_group("sim_renderer")
	if _sim_renderer != null:
		_sim_renderer.type_visible[type_idx] = pressed
		AgentPool._dirty = true


func _on_terr_toggled(type_idx: int, pressed: bool) -> void:
	_terr_active[type_idx] = pressed
	_terr_btns[type_idx].text = "◈" if pressed else "◇"
	if _territory_overlay == null:
		_territory_overlay = get_tree().get_first_node_in_group("territory_overlay")
	if _territory_overlay != null:
		_territory_overlay.set_type_active(type_idx, pressed)


func _update_counts() -> void:
	if not AgentPool:
		return
	var counts: PackedInt32Array = AgentPool._type_counts
	for t in 5:
		if t < counts.size():
			_count_labels[t].text = str(counts[t])
