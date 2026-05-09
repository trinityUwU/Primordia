extends Node2D

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE
const TEX_SIZE: int = 128

var _image: Image
var _texture: ImageTexture
var _mat: ShaderMaterial
var _tex_origin: Vector2i = Vector2i.ZERO
var _dirty: bool = true


func _ready() -> void:
	_image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_R8)
	_image.fill(Color(float(WorldGrid.BIOME_EARTH) / 4.0, 0, 0))
	_texture = ImageTexture.create_from_image(_image)

	var shader: Shader = load("res://shaders/biome.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	material = _mat

	WorldGrid.biome_changed.connect(func(_c): _dirty = true)


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half_world: Vector2 = vp_size * 0.5 / camera.zoom
	var cam_pos: Vector2 = camera.global_position
	var min_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos - half_world - Vector2(CHUNK_PX * 2, CHUNK_PX * 2))

	if _dirty or min_chunk != _tex_origin:
		_dirty = false
		_tex_origin = min_chunk
		_rebuild_texture()

	_mat.set_shader_parameter("chunk_px", CHUNK_PX)
	_mat.set_shader_parameter("cam_pos", cam_pos)
	_mat.set_shader_parameter("zoom", camera.zoom.x)
	_mat.set_shader_parameter("vp_size", vp_size)
	_mat.set_shader_parameter("tex_size", float(TEX_SIZE))
	_mat.set_shader_parameter("tex_origin", Vector2(float(_tex_origin.x), float(_tex_origin.y)))
	_mat.set_shader_parameter("biome_tex", _texture)
	queue_redraw()


func _draw() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	# Draw a screen-space rect in world coords (inverse of camera transform)
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	var cam_pos: Vector2 = camera.global_position
	draw_rect(Rect2(cam_pos - half, half * 2.0), Color.WHITE)


func _rebuild_texture() -> void:
	for py in TEX_SIZE:
		for px in TEX_SIZE:
			var coord: Vector2i = Vector2i(_tex_origin.x + px, _tex_origin.y + py)
			var biome: int = WorldGrid.get_chunk_biome(coord)
			_image.set_pixel(px, py, Color(float(biome) / 4.0, 0, 0, 1))
	_texture.update(_image)
