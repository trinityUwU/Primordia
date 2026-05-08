extends Node2D

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE
# Counts above this are treated as max density (full brightness)
const DENSITY_CAP: float = 200.0

# Type index → shader v_type value (matches density_fog.gdshader)
const TYPE_VISUAL: Array[float] = [0.0, 2.0, 3.0, 4.0, 5.0]  # bact, virus, proto, plant, fungi

var _multimesh: MultiMesh
var _mmi: MultiMeshInstance2D
var _allocated: int = 0


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
		mat.render_priority = 1  # draw above biome, below UI
		_mmi.material = mat
		_mmi.z_index = 1

	add_child(_mmi)


func _process(_delta: float) -> void:
	if not AgentPool._dirty:
		return
	_update_fog()


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
