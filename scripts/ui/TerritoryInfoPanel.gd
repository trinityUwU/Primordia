extends Control

const TYPE_NAMES: Array[String] = ["Bacteria", "Virus", "Protozoa", "Plants", "Fungi"]
const TYPE_COLORS: Array[Color] = [
	Color(0.310, 0.765, 0.969, 1.0),
	Color(0.937, 0.604, 0.604, 1.0),
	Color(0.808, 0.576, 0.847, 1.0),
	Color(0.647, 0.839, 0.655, 1.0),
	Color(1.000, 0.800, 0.502, 1.0),
]

@onready var _title: Label = $Panel/VBox/Title
@onready var _counts_container: VBoxContainer = $Panel/VBox/Counts
@onready var _btn_close: Button = $Panel/VBox/BtnClose


func _ready() -> void:
	hide()
	_btn_close.pressed.connect(hide)


func show_for_chunk(chunk_coord: Vector2i, agents: Array[int], visible_rect: Rect2) -> void:
	_title.text = "Chunk (%d, %d)" % [chunk_coord.x, chunk_coord.y]
	_populate_counts(agents, visible_rect)

	# Position near mouse, stay in viewport
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = $Panel.size
	var mp: Vector2 = get_viewport().get_mouse_position()
	var pos: Vector2 = mp + Vector2(12.0, 12.0)
	pos.x = minf(pos.x, vp_size.x - panel_size.x - 8.0)
	pos.y = minf(pos.y, vp_size.y - panel_size.y - 8.0)
	$Panel.position = pos

	show()


func _populate_counts(agents: Array[int], visible_rect: Rect2) -> void:
	for child in _counts_container.get_children():
		child.queue_free()

	var counts: Array[int] = [0, 0, 0, 0, 0]
	var visible_counts: Array[int] = [0, 0, 0, 0, 0]
	for i in agents:
		var t: int = AgentPool.agent_type[i]
		if t < 0 or t >= 5:
			continue
		counts[t] += 1
		var pos := Vector2(AgentPool.pos_x[i], AgentPool.pos_y[i])
		if visible_rect.has_point(pos):
			visible_counts[t] += 1

	var total: int = 0
	var total_visible: int = 0
	for t in 5:
		total += counts[t]
		total_visible += visible_counts[t]

	# Summary row
	var summary: Label = Label.new()
	summary.text = "%d total  ·  %d visible" % [total, total_visible]
	summary.add_theme_font_size_override("font_size", 11)
	summary.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counts_container.add_child(summary)

	for t in 5:
		if counts[t] == 0:
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var dot: Label = Label.new()
		dot.text = "●"
		dot.add_theme_color_override("font_color", TYPE_COLORS[t])
		dot.add_theme_font_size_override("font_size", 11)

		var name_lbl: Label = Label.new()
		name_lbl.text = TYPE_NAMES[t]
		name_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var count_lbl: Label = Label.new()
		count_lbl.text = "%d  (%d)" % [counts[t], visible_counts[t]]
		count_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		count_lbl.add_theme_font_size_override("font_size", 12)

		row.add_child(dot)
		row.add_child(name_lbl)
		row.add_child(count_lbl)
		_counts_container.add_child(row)
