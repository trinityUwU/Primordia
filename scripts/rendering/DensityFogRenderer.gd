extends Node2D

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE
const DENSITY_CAP: float = 200.0
const TYPE_VISUAL: Array[float] = [0.0, 2.0, 3.0, 4.0, 5.0]
const TYPE_NAMES: Array[String] = ["Bacteria", "Virus", "Protozoa", "Plants", "Fungi"]

var _multimesh: MultiMesh
var _mmi: MultiMeshInstance2D
var _allocated: int = 0
var _tooltip: Label


func _ready() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_custom_data = true
	_multimesh.instance_count = 0

	var quad := QuadMesh.new()
	quad.size = Vector2(CHUNK_PX, CHUNK_PX)
	_multimesh.mesh = quad

	_mmi = MultiMeshInstance2D.new()
	_mmi.multimesh = _multimesh

	var shader: Shader = load("res://shaders/density_fog.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.render_priority = 1
		_mmi.material = mat
		_mmi.z_index = 1

	add_child(_mmi)
	_setup_tooltip()


func _setup_tooltip() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 9
	add_child(canvas_layer)
	_tooltip = Label.new()
	_tooltip.visible = false
	_tooltip.add_theme_font_size_override("font_size", 12)
	canvas_layer.add_child(_tooltip)


func _process(_delta: float) -> void:
	if AgentPool._dirty:
		_update_fog()
	_update_lod_alpha()
	_update_tooltip()


func _update_lod_alpha() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null or _mmi.material == null:
		return
	var mat := _mmi.material as ShaderMaterial
	if mat == null:
		return
	var vp_x: float = get_viewport().get_visible_rect().size.x
	var base_zoom: float = vp_x / 1920.0
	var zoom_min: float = base_zoom * 0.25
	var zoom_max: float = base_zoom * 2.0  # fade complete at 2x base zoom
	var t: float = clampf((camera.zoom.x - zoom_min) / (zoom_max - zoom_min), 0.0, 1.0)
	mat.set_shader_parameter("lod_alpha", 1.0 - t)


func _update_fog() -> void:
	var aggregate: Dictionary = PopulationLOD._aggregate
	if aggregate.is_empty():
		_multimesh.visible_instance_count = 0
		return

	var needed: int = aggregate.size()
	if needed > _allocated:
		_allocated = needed + 64
		_multimesh.instance_count = _allocated

	var slot: int = 0
	for coord in aggregate:
		var counts: PackedInt32Array = aggregate[coord]
		var total: int = 0
		var dominant_type: int = 0
		var dominant_count: int = 0
		for t in PopulationLOD.TYPE_COUNT:
			var c: int = counts[t]
			total += c
			if c > dominant_count:
				dominant_count = c
				dominant_type = t

		if total <= 0:
			continue

		var density: float = clampf(float(total) / DENSITY_CAP, 0.05, 1.0)
		var v_type: float = TYPE_VISUAL[clampi(dominant_type, 0, 4)]
		var center: Vector2 = Vector2(coord.x, coord.y) * CHUNK_PX + Vector2(CHUNK_PX * 0.5, CHUNK_PX * 0.5)

		_multimesh.set_instance_transform_2d(slot, Transform2D(0.0, Vector2.ONE, 0.0, center))
		_multimesh.set_instance_custom_data(slot, Color(v_type, density, 0.0, 0.0))
		slot += 1

	_multimesh.visible_instance_count = slot


func _update_tooltip() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		_tooltip.visible = false
		return

	var mouse_screen: Vector2 = get_viewport().get_mouse_position()
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_world: Vector2 = camera.global_position + (mouse_screen - vp_size * 0.5) / camera.zoom.x

	var chunk_coord: Vector2i = Vector2i(
		floori(mouse_world.x / CHUNK_PX),
		floori(mouse_world.y / CHUNK_PX)
	)

	if not PopulationLOD._aggregate.has(chunk_coord):
		_tooltip.visible = false
		return

	var counts: PackedInt32Array = PopulationLOD._aggregate[chunk_coord]
	var total: int = 0
	for t in PopulationLOD.TYPE_COUNT:
		total += counts[t]
	if total <= 0:
		_tooltip.visible = false
		return

	var lines: Array[String] = ["[Virtual — %d total]" % total]
	for t in PopulationLOD.TYPE_COUNT:
		if counts[t] > 0:
			lines.append("%s: %d" % [TYPE_NAMES[t], counts[t]])
	_tooltip.text = "\n".join(lines)
	_tooltip.position = mouse_screen + Vector2(12.0, -8.0)
	_tooltip.visible = true
