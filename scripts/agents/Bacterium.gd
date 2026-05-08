class_name Bacterium
extends AgentBase

const DEFAULT_GENOME: Dictionary = {
	"move_speed": 30.0,
	"metabolism": 0.02,
	"division_threshold": 1.0,
	"division_energy_cost": 0.6,
	"mutation_rate": 0.02,
	"resistance": 0.5,
	"virulence": 0.1,
	"gram_positive": true,
}

# Run-and-tumble state
var _run_timer: int = 0
var _is_spore: bool = false
var _spore_timer: int = 0
const SPORULATION_TICKS: int = 300


func _ready() -> void:
	if genome.is_empty():
		genome = DEFAULT_GENOME.duplicate()
	max_age = 3000
	size = 1.0
	speed = genome.get("move_speed", 30.0)
	_direction = Vector2.from_angle(randf() * TAU)


func _tick(tick_num: int) -> void:
	if not alive:
		return
	age += 1
	if age > max_age:
		die()
		return
	if _is_spore:
		_tick_spore()
		return
	_tick_active(tick_num)


func _tick_active(_tick_num: int) -> void:
	consume_energy(genome.get("metabolism", 0.02))
	if not alive:
		return
	_move()
	_consume_nutrients()
	_check_division()
	_check_sporulation()


func _tick_spore() -> void:
	_spore_timer += 1
	var gp: Vector2i = get_grid_pos()
	var nutrients: float = WorldGrid.get_cell_value(gp.x, gp.y, "nutrients")
	var temp: float = WorldGrid.get_cell_value(gp.x, gp.y, "temperature")
	if nutrients > 0.3 and temp >= 5.0 and _spore_timer > 100:
		_is_spore = false
		energy = 0.3


func _move() -> void:
	_run_timer -= 1
	if _run_timer <= 0:
		_tumble()
	var delta_pos: Vector2 = _direction * (speed / 60.0)
	global_position += delta_pos
	_clamp_to_world()


func _tumble() -> void:
	var gp: Vector2i = get_grid_pos()
	var gradient: Vector2 = _sample_nutrient_gradient(gp)
	if gradient.length_squared() > 0.0001:
		var bias: float = clampf(gradient.length() * 5.0, 0.0, 1.0)
		_direction = _direction.lerp(gradient.normalized(), bias * 0.6).normalized()
	else:
		_direction = Vector2.from_angle(randf() * TAU)
	_run_timer = randi_range(30, 90)


func _sample_nutrient_gradient(gp: Vector2i) -> Vector2:
	var x: int = gp.x
	var y: int = gp.y
	var r: int = 3
	var cx: float = WorldGrid.get_cell_value(clamp(x + r, 0, WorldGrid.GRID_WIDTH - 1), y, "nutrients")
	var lx: float = WorldGrid.get_cell_value(clamp(x - r, 0, WorldGrid.GRID_WIDTH - 1), y, "nutrients")
	var cy: float = WorldGrid.get_cell_value(x, clamp(y + r, 0, WorldGrid.GRID_HEIGHT - 1), "nutrients")
	var uy: float = WorldGrid.get_cell_value(x, clamp(y - r, 0, WorldGrid.GRID_HEIGHT - 1), "nutrients")
	return Vector2(cx - lx, cy - uy)


func _consume_nutrients() -> void:
	var gp: Vector2i = get_grid_pos()
	var available: float = WorldGrid.get_cell_value(gp.x, gp.y, "nutrients")
	var uptake: float = minf(0.03, available)
	WorldGrid.set_cell_value(gp.x, gp.y, "nutrients", available - uptake)
	energy = minf(energy + uptake, 2.0)


func _check_division() -> void:
	var threshold: float = genome.get("division_threshold", 1.0)
	if energy < threshold:
		return
	if PopulationManager.get_population_count() >= PopulationManager.MAX_AGENTS:
		return
	var child_genome: Dictionary = _mutate_genome()
	var offset: Vector2 = Vector2.from_angle(randf() * TAU) * size * 2.0
	var child: Bacterium = PopulationManager.spawn_bacterium(global_position + offset, child_genome)
	var cost: float = genome.get("division_energy_cost", 0.6)
	child.energy = cost * 0.5
	energy -= cost * 0.5


func _mutate_genome() -> Dictionary:
	var child: Dictionary = genome.duplicate()
	var rate: float = genome.get("mutation_rate", 0.02)
	for key in child.keys():
		if typeof(child[key]) == TYPE_FLOAT:
			if randf() < rate:
				child[key] = child[key] * (1.0 + randfn(0.0, 0.08))
		elif typeof(child[key]) == TYPE_BOOL and key == "gram_positive":
			if randf() < 0.001:
				child[key] = not child[key]
	return child


func _check_sporulation() -> void:
	if not genome.get("gram_positive", true):
		return
	var gp: Vector2i = get_grid_pos()
	var nutrients: float = WorldGrid.get_cell_value(gp.x, gp.y, "nutrients")
	var temp: float = WorldGrid.get_cell_value(gp.x, gp.y, "temperature")
	if nutrients < 0.05 and temp < 5.0:
		_is_spore = true
		_spore_timer = 0


func _clamp_to_world() -> void:
	var w: float = WorldGrid.GRID_WIDTH * WorldGrid.CELL_SIZE
	var h: float = WorldGrid.GRID_HEIGHT * WorldGrid.CELL_SIZE
	global_position.x = clampf(global_position.x, 0.0, w)
	global_position.y = clampf(global_position.y, 0.0, h)


func is_spore() -> bool:
	return _is_spore
