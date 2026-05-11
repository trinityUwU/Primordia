extends Node2D

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE
const TEX_SIZE: int = 64
const MARGIN: int = 8
const REBUILD_COOLDOWN: float = 0.3

# wu_per_px threshold: above this the shader computes biomes from noise directly
# Below: texture-based with Voronoi borders
const LOD_PROCEDURAL_THRESHOLD: float = 8.0

var _image: Image
var _texture: ImageTexture
var _mat: ShaderMaterial
var _tex_origin: Vector2i = Vector2i(-9999, -9999)
var _dirty: bool = true
var _cooldown: float = 0.0

var _canvas: CanvasLayer
var _rect: ColorRect


func _ready() -> void:
	_image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_R8)
	_texture = ImageTexture.create_from_image(_image)

	var shader: Shader = load("res://shaders/biome.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = shader

	_canvas = CanvasLayer.new()
	_canvas.layer = -10
	add_child(_canvas)

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rect.material = _mat
	_canvas.add_child(_rect)

	WorldGrid.biome_changed.connect(func(_c): _dirty = true)

	# Pass WorldGen noise params to shader once (seed-based hash reproduced in GLSL)
	_mat.set_shader_parameter("world_seed_f", float(WorldGen.world_seed % 100000))
	_mat.set_shader_parameter("noise_alt_freq", 0.004)
	_mat.set_shader_parameter("noise_hum_freq", 0.003)


func _process(delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return

	_cooldown -= delta
	var cam_pos: Vector2 = camera.global_position
	var zoom: float = camera.zoom.x
	var wu_per_px: float = 1.0 / zoom

	# Only rebuild texture when in texture-based LOD range
	if wu_per_px <= LOD_PROCEDURAL_THRESHOLD:
		var center_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos)
		var needs_rebuild: bool = _dirty
		if not needs_rebuild:
			var rel: Vector2i = center_chunk - _tex_origin
			needs_rebuild = (
				rel.x < MARGIN or rel.x >= TEX_SIZE - MARGIN or
				rel.y < MARGIN or rel.y >= TEX_SIZE - MARGIN
			)
		if needs_rebuild and _cooldown <= 0.0:
			_dirty = false
			_cooldown = REBUILD_COOLDOWN
			_tex_origin = center_chunk - Vector2i(TEX_SIZE / 2, TEX_SIZE / 2)
			_rebuild_texture()

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("biome_tex", _texture)
	_mat.set_shader_parameter("tex_size", float(TEX_SIZE))
	_mat.set_shader_parameter("tex_origin", Vector2(float(_tex_origin.x), float(_tex_origin.y)))
	_mat.set_shader_parameter("chunk_px", CHUNK_PX)
	_mat.set_shader_parameter("cam_pos", cam_pos)
	_mat.set_shader_parameter("zoom", zoom)
	_mat.set_shader_parameter("vp_size", vp_size)
	_mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)


func _rebuild_texture() -> void:
	var data: PackedByteArray = PackedByteArray()
	data.resize(TEX_SIZE * TEX_SIZE)
	var bmap: Dictionary = WorldGrid._biome_map
	var i: int = 0
	for py in TEX_SIZE:
		for px in TEX_SIZE:
			var coord: Vector2i = Vector2i(_tex_origin.x + px, _tex_origin.y + py)
			var biome: int
			if bmap.has(coord):
				biome = bmap[coord]
			else:
				biome = WorldGen.get_biome(coord)
				bmap[coord] = biome
			data[i] = int(float(biome) / 4.0 * 255.0 + 0.5)
			i += 1
	_image = Image.create_from_data(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_R8, data)
	_texture.update(_image)
