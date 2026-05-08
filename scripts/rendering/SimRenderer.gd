extends Node2D

const CUSTOM_GRAM_POS: float = 0.0
const CUSTOM_GRAM_NEG: float = 1.0
const CUSTOM_SPORE: float = 2.0
const CUSTOM_VIRUS: float = 3.0
const CUSTOM_DEAD: float = 4.0
const CUSTOM_PROTOZOA: float = 5.0
const CUSTOM_PLANT: float = 6.0
const CUSTOM_FUNGI: float = 7.0
const CLUSTER_CELL_PX: float = 24.0
const CLUSTER_THRESHOLD: int = 3

var _multimesh: MultiMesh
var _mmi: MultiMeshInstance2D
var _shader_material: ShaderMaterial
var _tooltip: Label
var _cluster_tooltip: Dictionary = {}


func _ready() -> void:
	_setup_multimesh()
	_setup_shader()
	_setup_tooltip()


func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_custom_data = true
	_multimesh.instance_count = AgentPool.MAX_AGENTS
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(10.0, 10.0)
	_multimesh.mesh = quad
	_mmi = MultiMeshInstance2D.new()
	_mmi.multimesh = _multimesh
	add_child(_mmi)


func _setup_shader() -> void:
	var shader: Shader = load("res://shaders/agent.gdshader")
	if shader == null:
		return
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_mmi.material = _shader_material


func _setup_tooltip() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	_tooltip = Label.new()
	_tooltip.visible = false
	canvas_layer.add_child(_tooltip)


func _process(_delta: float) -> void:
	if not AgentPool._dirty:
		return
	AgentPool._dirty = false
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var cull_rect: Rect2 = _get_cull_rect(camera)
	_cluster_tooltip.clear()
	var visible_count: int = _fill_instances(cull_rect, camera)
	_multimesh.visible_instance_count = visible_count


func _get_cull_rect(camera: Camera2D) -> Rect2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	return Rect2(camera.global_position - half, half * 2.0).grow(50.0)


func _world_to_screen(world_pos: Vector2, camera: Camera2D) -> Vector2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	return (world_pos - camera.global_position) * camera.zoom + vp_size * 0.5


func _build_clusters(cull_rect: Rect2, camera: Camera2D) -> Dictionary:
	var cells: Dictionary = {}
	for i in AgentPool.count:
		var f: int = AgentPool.flags[i]
		var px: float = AgentPool.pos_x[i]
		var py: float = AgentPool.pos_y[i]
		if not cull_rect.has_point(Vector2(px, py)):
			continue
		var screen_pos: Vector2 = _world_to_screen(Vector2(px, py), camera)
		var cell: Vector2i = Vector2i(
			int(screen_pos.x / CLUSTER_CELL_PX),
			int(screen_pos.y / CLUSTER_CELL_PX)
		)
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(i)
	return cells


func _fill_instances(cull_rect: Rect2, camera: Camera2D) -> int:
	var cells: Dictionary = _build_clusters(cull_rect, camera)
	var slot: int = 0
	for cell in cells:
		var indices: Array = cells[cell]
		if indices.size() <= CLUSTER_THRESHOLD:
			slot = _write_individual_agents(indices, slot)
		else:
			slot = _write_cluster(cell, indices, slot, camera)
	return slot


func _write_individual_agents(indices: Array, slot: int) -> int:
	for i in indices:
		var f: int = AgentPool.flags[i]
		var px: float = AgentPool.pos_x[i]
		var py: float = AgentPool.pos_y[i]
		var transform: Transform2D = _build_transform(i, px, py)
		var custom: Color = _build_custom(i, f)
		_multimesh.set_instance_transform_2d(slot, transform)
		_multimesh.set_instance_custom_data(slot, custom)
		slot += 1
	return slot


func _write_cluster(cell: Vector2i, indices: Array, slot: int, camera: Camera2D) -> int:
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var type_counts: Dictionary = {}
	for i in indices:
		sum_x += AgentPool.pos_x[i]
		sum_y += AgentPool.pos_y[i]
		var t: int = AgentPool.agent_type[i]
		type_counts[t] = type_counts.get(t, 0) + 1
	var n: int = indices.size()
	var cx: float = sum_x / n
	var cy: float = sum_y / n
	var cluster_size: float = log(float(n)) * 1.5 + 1.0
	var majority_type: int = _majority_key(type_counts)
	var fake_i: int = indices[0]
	var transform: Transform2D = Transform2D(0.0, Vector2(cluster_size, cluster_size), 0.0, Vector2(cx, cy))
	var custom: Color = _build_custom(fake_i, AgentPool.flags[fake_i])
	_multimesh.set_instance_transform_2d(slot, transform)
	_multimesh.set_instance_custom_data(slot, custom)
	_cluster_tooltip[cell] = {
		"count": n,
		"type_counts": type_counts,
		"majority": majority_type,
		"world_pos": Vector2(cx, cy)
	}
	return slot + 1


func _majority_key(type_counts: Dictionary) -> int:
	var best_key: int = 0
	var best_val: int = 0
	for k in type_counts:
		if type_counts[k] > best_val:
			best_val = type_counts[k]
			best_key = k
	return best_key


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var mouse_pos: Vector2 = (event as InputEventMouseMotion).position
	var cell: Vector2i = Vector2i(
		int(mouse_pos.x / CLUSTER_CELL_PX),
		int(mouse_pos.y / CLUSTER_CELL_PX)
	)
	if _cluster_tooltip.has(cell):
		_show_tooltip(mouse_pos, _cluster_tooltip[cell])
	else:
		_tooltip.visible = false


func _show_tooltip(mouse_pos: Vector2, data: Dictionary) -> void:
	var type_counts: Dictionary = data["type_counts"]
	var parts: Array = []
	for t in type_counts:
		var name_str: String
		if t == AgentPool.TYPE_BACTERIUM:
			name_str = "Bacterium"
		elif t == AgentPool.TYPE_VIRUS:
			name_str = "Virus"
		elif t == AgentPool.TYPE_PROTOZOA:
			name_str = "Protozoa"
		elif t == AgentPool.TYPE_PLANT:
			name_str = "Plant"
		elif t == AgentPool.TYPE_FUNGI:
			name_str = "Fungi"
		else:
			name_str = "Unknown"
		parts.append("%s x%d" % [name_str, type_counts[t]])
	_tooltip.text = " | ".join(parts)
	_tooltip.position = mouse_pos + Vector2(10.0, -20.0)
	_tooltip.visible = true


func _build_transform(i: int, px: float, py: float) -> Transform2D:
	var s: float = AgentPool.size_arr[i]
	if s <= 0.0:
		s = 1.0
	return Transform2D(0.0, Vector2(s, s), 0.0, Vector2(px, py))


func _build_custom(i: int, f: int) -> Color:
	if f & AgentPool.FLAG_ALIVE == 0:
		var alpha: float = clampf(float(AgentPool.dead_timer[i]) / 300.0, 0.0, 1.0)
		return Color(CUSTOM_DEAD, alpha, 0.0, 0.0)
	if AgentPool.agent_type[i] == AgentPool.TYPE_VIRUS:
		return Color(CUSTOM_VIRUS, 0.0, 0.0, 0.0)
	if AgentPool.agent_type[i] == AgentPool.TYPE_PROTOZOA:
		return Color(CUSTOM_PROTOZOA, 0.0, 0.0, 0.0)
	if AgentPool.agent_type[i] == AgentPool.TYPE_PLANT:
		return Color(CUSTOM_PLANT, 0.0, 0.0, 0.0)
	if AgentPool.agent_type[i] == AgentPool.TYPE_FUNGI:
		return Color(CUSTOM_FUNGI, 0.0, 0.0, 0.0)
	if f & AgentPool.FLAG_SPORE:
		return Color(CUSTOM_SPORE, 0.0, 0.0, 0.0)
	if f & AgentPool.FLAG_GRAM_POS:
		return Color(CUSTOM_GRAM_POS, 0.0, 0.0, 0.0)
	return Color(CUSTOM_GRAM_NEG, 0.0, 0.0, 0.0)
