extends Node2D

const CUSTOM_GRAM_POS: float = 0.0
const CUSTOM_GRAM_NEG: float = 1.0
const CUSTOM_SPORE: float = 2.0
const CUSTOM_VIRUS: float = 3.0
const CUSTOM_DEAD: float = 4.0

var _multimesh: MultiMesh
var _mmi: MultiMeshInstance2D
var _shader_material: ShaderMaterial


func _ready() -> void:
	_setup_multimesh()
	_setup_shader()


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


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var cull_rect: Rect2 = _get_cull_rect(camera)
	var visible_count: int = _fill_instances(cull_rect)
	_multimesh.visible_instance_count = visible_count


func _get_cull_rect(camera: Camera2D) -> Rect2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	return Rect2(camera.global_position - half, half * 2.0).grow(50.0)


func _fill_instances(cull_rect: Rect2) -> int:
	var visible: int = 0
	for i in AgentPool.count:
		var f: int = AgentPool.flags[i]
		var px: float = AgentPool.pos_x[i]
		var py: float = AgentPool.pos_y[i]
		if not cull_rect.has_point(Vector2(px, py)):
			continue
		var transform: Transform2D = _build_transform(i, px, py)
		var custom: Color = _build_custom(i, f)
		_multimesh.set_instance_transform_2d(visible, transform)
		_multimesh.set_instance_custom_data(visible, custom)
		visible += 1
	return visible


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
	if f & AgentPool.FLAG_SPORE:
		return Color(CUSTOM_SPORE, 0.0, 0.0, 0.0)
	if f & AgentPool.FLAG_GRAM_POS:
		return Color(CUSTOM_GRAM_POS, 0.0, 0.0, 0.0)
	return Color(CUSTOM_GRAM_NEG, 0.0, 0.0, 0.0)
