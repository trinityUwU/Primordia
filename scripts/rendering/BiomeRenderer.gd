extends Node2D

# Full-screen biome renderer.
# Architecture: CanvasLayer(layer=-1) → ColorRect(full anchors) + ShaderMaterial
# The ColorRect covers the screen; shader reconstructs world pos from cam uniforms.
# Biome map is a 128×128 R8 texture (1 pixel = 1 chunk).

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE
const TEX_SIZE: int = 128

var _image: Image
var _texture: ImageTexture
var _mat: ShaderMaterial
var _tex_origin: Vector2i = Vector2i(-9999, -9999)
var _dirty: bool = true

var _canvas: CanvasLayer
var _rect: ColorRect


func _ready() -> void:
	_image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_R8)
	_image.fill(Color(float(WorldGrid.BIOME_EARTH) / 4.0, 0.0, 0.0, 1.0))
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
	_rect.material = _mat
	_canvas.add_child(_rect)

	WorldGrid.biome_changed.connect(func(_c): _dirty = true)


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom: float = camera.zoom.x
	var cam_pos: Vector2 = camera.global_position
	var half_world: Vector2 = vp_size * 0.5 / zoom

	var min_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos - half_world - Vector2(CHUNK_PX * 2, CHUNK_PX * 2))

	if _dirty or min_chunk != _tex_origin:
		_dirty = false
		_tex_origin = min_chunk
		_rebuild_texture()

	_mat.set_shader_parameter("biome_tex", _texture)
	_mat.set_shader_parameter("tex_size", float(TEX_SIZE))
	_mat.set_shader_parameter("tex_origin", Vector2(float(_tex_origin.x), float(_tex_origin.y)))
	_mat.set_shader_parameter("chunk_px", CHUNK_PX)
	_mat.set_shader_parameter("cam_pos", cam_pos)
	_mat.set_shader_parameter("zoom", zoom)
	_mat.set_shader_parameter("vp_size", vp_size)


func _rebuild_texture() -> void:
	for py in TEX_SIZE:
		for px in TEX_SIZE:
			var biome: int = WorldGrid.get_chunk_biome(Vector2i(_tex_origin.x + px, _tex_origin.y + py))
			_image.set_pixel(px, py, Color(float(biome) / 4.0, 0.0, 0.0, 1.0))
	_texture.update(_image)
