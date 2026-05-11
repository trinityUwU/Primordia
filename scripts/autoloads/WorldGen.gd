extends Node

# WorldGen — procedural world generation
# 1 world unit = 1 μm. Noise coords are in chunk space (integer chunk coords).
# All generation is deterministic given world_seed.

var world_seed: int = 0

var _noise_altitude: FastNoiseLite
var _noise_humidity: FastNoiseLite
var _noise_temperature: FastNoiseLite
var _noise_detail: FastNoiseLite   # fine-grain variation within biome fields


func _ready() -> void:
	randomize()
	world_seed = randi()
	_init_noises()


func set_seed(s: int) -> void:
	world_seed = s
	_init_noises()


func _init_noises() -> void:
	_noise_altitude = FastNoiseLite.new()
	_noise_altitude.seed = world_seed
	_noise_altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_altitude.frequency = 0.004
	_noise_altitude.fractal_octaves = 5
	_noise_altitude.fractal_lacunarity = 2.0
	_noise_altitude.fractal_gain = 0.5

	_noise_humidity = FastNoiseLite.new()
	_noise_humidity.seed = world_seed + 1000
	_noise_humidity.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_humidity.frequency = 0.003
	_noise_humidity.fractal_octaves = 4
	_noise_humidity.fractal_lacunarity = 2.0
	_noise_humidity.fractal_gain = 0.45

	_noise_temperature = FastNoiseLite.new()
	_noise_temperature.seed = world_seed + 2000
	_noise_temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_temperature.frequency = 0.002
	_noise_temperature.fractal_octaves = 3
	_noise_temperature.fractal_lacunarity = 2.0
	_noise_temperature.fractal_gain = 0.4

	_noise_detail = FastNoiseLite.new()
	_noise_detail.seed = world_seed + 3000
	_noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_detail.frequency = 0.05
	_noise_detail.fractal_octaves = 2


# Returns biome type for chunk coord — 2 noise lookups only
func get_biome(chunk_coord: Vector2i) -> int:
	var cx: float = float(chunk_coord.x)
	var cy: float = float(chunk_coord.y)
	var alt: float = _normalize(_noise_altitude.get_noise_2d(cx, cy))
	var hum: float = _normalize(_noise_humidity.get_noise_2d(cx, cy))
	return _biome_from(alt, hum)


# Batch fill: returns PackedByteArray of biomes for a rect of chunks
# Each byte = biome id. Row-major, origin at (ox, oy), size w×h
func get_biome_rect(ox: int, oy: int, w: int, h: int, overrides: Dictionary) -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	data.resize(w * h)
	var i: int = 0
	for y in h:
		for x in w:
			var coord := Vector2i(ox + x, oy + y)
			if overrides.has(coord):
				data[i] = overrides[coord]
			else:
				var cx: float = float(coord.x)
				var cy: float = float(coord.y)
				var alt: float = _normalize(_noise_altitude.get_noise_2d(cx, cy))
				var hum: float = _normalize(_noise_humidity.get_noise_2d(cx, cy))
				data[i] = _biome_from(alt, hum)
			i += 1
	return data


func _biome_from(alt: float, hum: float) -> int:
	if alt > 0.72:                        return WorldGrid.BIOME_ROCK
	if alt < 0.26:                        return WorldGrid.BIOME_WATER
	if alt < 0.35 and hum > 0.60:         return WorldGrid.BIOME_WATER
	if hum > 0.62:                        return WorldGrid.BIOME_WOOD
	if hum > 0.35:                        return WorldGrid.BIOME_GRASS
	return WorldGrid.BIOME_EARTH


# Fills chunk fields with procedurally generated initial values
# Adds per-cell noise variation on top of biome defaults
func generate_chunk_fields(chunk_coord: Vector2i, biome: int, fields: Dictionary) -> void:
	var cx: float = float(chunk_coord.x)
	var cy: float = float(chunk_coord.y)
	var alt: float  = _normalize(_noise_altitude.get_noise_2d(cx, cy))
	var hum: float  = _normalize(_noise_humidity.get_noise_2d(cx, cy))
	var temp_n: float = _normalize(_noise_temperature.get_noise_2d(cx, cy))

	var defaults: Dictionary = WorldGrid.BIOME_DEFAULTS[biome]
	var s: int = WorldGrid.CHUNK_SIZE

	for ly in s:
		for lx in s:
			# Cell-level world coords for detail noise
			var wx: float = cx * s + lx
			var wy: float = cy * s + ly
			var detail: float = _noise_detail.get_noise_2d(wx * 0.1, wy * 0.1) * 0.08
			var idx: int = ly * s + lx

			match biome:
				WorldGrid.BIOME_WATER:
					fields["nutrients"][idx]    = clampf(0.08 + hum * 0.12 + detail, 0.0, 0.3)
					fields["water"][idx]        = clampf(0.90 + detail * 0.5, 0.7, 1.0)
					fields["temperature"][idx]  = clampf(8.0 + temp_n * 14.0 + detail * 10.0, 2.0, 25.0)
					fields["oxygen"][idx]       = clampf(0.16 + detail * 0.04, 0.10, 0.25)
					fields["ph"][idx]           = clampf(7.8 + detail * 0.6, 7.0, 9.0)
					fields["toxins"][idx]       = 0.0
					fields["light"][idx]        = clampf(0.5 + alt * 0.2 + detail, 0.3, 0.8)

				WorldGrid.BIOME_ROCK:
					fields["nutrients"][idx]    = clampf(0.01 + detail * 0.02, 0.0, 0.05)
					fields["water"][idx]        = clampf(0.04 + detail * 0.04, 0.0, 0.12)
					fields["temperature"][idx]  = clampf(20.0 + temp_n * 18.0 + detail * 8.0, 5.0, 45.0)
					fields["oxygen"][idx]       = clampf(0.21 + detail * 0.02, 0.18, 0.24)
					fields["ph"][idx]           = clampf(7.2 + detail * 0.5, 6.5, 8.0)
					fields["toxins"][idx]       = 0.0
					fields["light"][idx]        = clampf(0.85 + detail * 0.1, 0.7, 1.0)

				WorldGrid.BIOME_EARTH:
					fields["nutrients"][idx]    = clampf(0.25 + hum * 0.2 + detail * 0.15, 0.1, 0.6)
					fields["water"][idx]        = clampf(0.25 + hum * 0.3 + detail * 0.1, 0.1, 0.6)
					fields["temperature"][idx]  = clampf(15.0 + temp_n * 16.0 + detail * 6.0, 5.0, 40.0)
					fields["oxygen"][idx]       = clampf(0.20 + detail * 0.03, 0.17, 0.24)
					fields["ph"][idx]           = clampf(6.2 + detail * 0.8, 5.5, 7.5)
					fields["toxins"][idx]       = 0.0
					fields["light"][idx]        = clampf(0.80 + detail * 0.15, 0.6, 1.0)

				WorldGrid.BIOME_GRASS:
					fields["nutrients"][idx]    = clampf(0.45 + hum * 0.25 + detail * 0.15, 0.2, 0.85)
					fields["water"][idx]        = clampf(0.40 + hum * 0.3 + detail * 0.1, 0.2, 0.75)
					fields["temperature"][idx]  = clampf(14.0 + temp_n * 12.0 + detail * 5.0, 5.0, 35.0)
					fields["oxygen"][idx]       = clampf(0.22 + detail * 0.04, 0.18, 0.30)
					fields["ph"][idx]           = clampf(6.5 + detail * 0.6, 5.8, 7.5)
					fields["toxins"][idx]       = 0.0
					fields["light"][idx]        = clampf(0.85 + detail * 0.12, 0.65, 1.0)

				WorldGrid.BIOME_WOOD:
					fields["nutrients"][idx]    = clampf(0.65 + hum * 0.2 + detail * 0.12, 0.4, 1.0)
					fields["water"][idx]        = clampf(0.60 + hum * 0.25 + detail * 0.08, 0.4, 0.95)
					fields["temperature"][idx]  = clampf(12.0 + temp_n * 10.0 + detail * 4.0, 4.0, 28.0)
					fields["oxygen"][idx]       = clampf(0.24 + detail * 0.05, 0.18, 0.35)
					fields["ph"][idx]           = clampf(4.8 + detail * 0.7, 4.0, 6.2)
					fields["toxins"][idx]       = 0.0
					fields["light"][idx]        = clampf(0.18 + detail * 0.1, 0.05, 0.35)

				_:
					for key in WorldGrid.FIELD_KEYS:
						fields[key][idx] = defaults[key]


func _normalize(v: float) -> float:
	return (v + 1.0) * 0.5


# Returns altitude [0,1] at chunk coord — used by shader/renderer
func get_altitude(chunk_coord: Vector2i) -> float:
	return _normalize(_noise_altitude.get_noise_2d(float(chunk_coord.x), float(chunk_coord.y)))


func get_humidity(chunk_coord: Vector2i) -> float:
	return _normalize(_noise_humidity.get_noise_2d(float(chunk_coord.x), float(chunk_coord.y)))


func get_temperature_norm(chunk_coord: Vector2i) -> float:
	return _normalize(_noise_temperature.get_noise_2d(float(chunk_coord.x), float(chunk_coord.y)))
