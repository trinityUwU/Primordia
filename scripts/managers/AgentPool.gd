extends Node

const MAX_AGENTS: int = 3000
const TYPE_BACTERIUM: int = 0
const TYPE_VIRUS: int = 1
const TYPE_PROTOZOA: int = 2
const TYPE_PLANT: int = 3
const TYPE_FUNGI: int = 4

# FSM states
const STATE_IDLE: int = 0
const STATE_SEEK: int = 1
const STATE_HUNT: int = 2
const STATE_REPRODUCE: int = 3

const FLAG_ALIVE: int = 1
const FLAG_GRAM_POS: int = 2
const FLAG_SPORE: int = 4

const TICK_STRIDE: int = 2
const DEAD_DECAY_TICKS: int = 300
const SPORE_MIN_TIMER: int = 100
const SPATIAL_CELL: float = 64.0

var count: int = 0
var _alive_count: int = 0
var _dirty: bool = false
var _needs_compact: bool = false
var _spatial: Dictionary = {}

var pos_x: PackedFloat32Array
var pos_y: PackedFloat32Array
var dir_x: PackedFloat32Array
var dir_y: PackedFloat32Array
var energy: PackedFloat32Array
var speed: PackedFloat32Array
var size_arr: PackedFloat32Array
var metabolism: PackedFloat32Array
var division_threshold: PackedFloat32Array
var mutation_rate: PackedFloat32Array
var resistance: PackedFloat32Array
var virulence: PackedFloat32Array

var age: PackedInt32Array
var max_age: PackedInt32Array
var agent_type: PackedInt32Array
var flags: PackedInt32Array
var dead_timer: PackedInt32Array
var run_timer: PackedInt32Array
var spore_timer: PackedInt32Array
var brain_state: PackedInt32Array
var target_i: PackedInt32Array    # index of target agent (-1 = none)
var sense_radius: PackedFloat32Array


func _ready() -> void:
	_resize_arrays(MAX_AGENTS)
	SimulationClock.tick_processed.connect(_on_tick)


func _resize_arrays(n: int) -> void:
	pos_x.resize(n);          pos_x.fill(0.0)
	pos_y.resize(n);          pos_y.fill(0.0)
	dir_x.resize(n);          dir_x.fill(1.0)
	dir_y.resize(n);          dir_y.fill(0.0)
	energy.resize(n);         energy.fill(0.0)
	speed.resize(n);          speed.fill(0.0)
	size_arr.resize(n);       size_arr.fill(0.0)
	metabolism.resize(n);     metabolism.fill(0.0)
	division_threshold.resize(n); division_threshold.fill(0.0)
	mutation_rate.resize(n);  mutation_rate.fill(0.0)
	resistance.resize(n);     resistance.fill(0.0)
	virulence.resize(n);      virulence.fill(0.0)
	age.resize(n);            age.fill(0)
	max_age.resize(n);        max_age.fill(0)
	agent_type.resize(n);     agent_type.fill(0)
	flags.resize(n);          flags.fill(0)
	dead_timer.resize(n);     dead_timer.fill(0)
	run_timer.resize(n);      run_timer.fill(0)
	spore_timer.resize(n);    spore_timer.fill(0)
	brain_state.resize(n);    brain_state.fill(0)
	target_i.resize(n);       target_i.fill(-1)
	sense_radius.resize(n);   sense_radius.fill(0.0)


func _find_free_slot() -> int:
	if count < MAX_AGENTS:
		return count
	for i in MAX_AGENTS:
		if flags[i] == 0:
			return i
	return -1


func spawn_bacterium(px: float, py: float, genome: Dictionary = {}) -> int:
	var i: int = _find_free_slot()
	if i < 0:
		return -1
	var angle: float = randf() * TAU
	var gram_pos: bool = genome.get("gram_positive", true)
	var f: int = FLAG_ALIVE
	if gram_pos:
		f |= FLAG_GRAM_POS
	pos_x[i]             = px
	pos_y[i]             = py
	dir_x[i]             = cos(angle)
	dir_y[i]             = sin(angle)
	energy[i]            = genome.get("energy", 1.0)
	speed[i]             = genome.get("move_speed", 30.0)
	size_arr[i]          = genome.get("size", 1.0)
	metabolism[i]        = genome.get("metabolism", 0.02)
	division_threshold[i]= genome.get("division_threshold", 1.0)
	mutation_rate[i]     = genome.get("mutation_rate", 0.02)
	resistance[i]        = genome.get("resistance", 0.5)
	virulence[i]         = genome.get("virulence", 0.1)
	age[i]               = 0
	max_age[i]           = genome.get("max_age", 3000)
	agent_type[i]        = TYPE_BACTERIUM
	flags[i]             = f
	dead_timer[i]        = 0
	run_timer[i]         = randi_range(30, 90)
	spore_timer[i]       = 0
	if i == count:
		count += 1
	_alive_count += 1
	return i


func spawn_virus(px: float, py: float) -> int:
	var i: int = _find_free_slot()
	if i < 0:
		return -1
	var angle: float = randf() * TAU
	pos_x[i]             = px
	pos_y[i]             = py
	dir_x[i]             = cos(angle)
	dir_y[i]             = sin(angle)
	energy[i]            = 1.0
	speed[i]             = 20.0
	size_arr[i]          = 0.4
	metabolism[i]        = 0.0
	division_threshold[i]= 999.0
	mutation_rate[i]     = 0.05
	resistance[i]        = 0.0
	virulence[i]         = 0.3
	age[i]               = 0
	max_age[i]           = 100
	agent_type[i]        = TYPE_VIRUS
	flags[i]             = FLAG_ALIVE
	dead_timer[i]        = 0
	run_timer[i]         = 0
	spore_timer[i]       = 0
	if i == count:
		count += 1
	_alive_count += 1
	return i


func spawn_protozoa(px: float, py: float) -> int:
	var i: int = _find_free_slot()
	if i < 0:
		return -1
	var angle: float = randf() * TAU
	pos_x[i]             = px
	pos_y[i]             = py
	dir_x[i]             = cos(angle)
	dir_y[i]             = sin(angle)
	energy[i]            = 3.0
	speed[i]             = 50.0
	size_arr[i]          = 2.5
	metabolism[i]        = 0.003
	division_threshold[i]= 5.0
	mutation_rate[i]     = 0.01
	resistance[i]        = 0.8
	virulence[i]         = 0.9
	age[i]               = 0
	max_age[i]           = 8000
	agent_type[i]        = TYPE_PROTOZOA
	flags[i]             = FLAG_ALIVE
	dead_timer[i]        = 0
	run_timer[i]         = 0
	spore_timer[i]       = 0
	brain_state[i]       = STATE_IDLE
	target_i[i]          = -1
	sense_radius[i]      = 200.0
	if i == count:
		count += 1
	_alive_count += 1
	return i


func spawn_plant(px: float, py: float) -> int:
	var i: int = _find_free_slot()
	if i < 0:
		return -1
	pos_x[i]             = px
	pos_y[i]             = py
	dir_x[i]             = 0.0
	dir_y[i]             = 0.0
	energy[i]            = 1.0
	speed[i]             = 0.0
	size_arr[i]          = 3.0
	metabolism[i]        = 0.005
	division_threshold[i]= 2.0
	mutation_rate[i]     = 0.005
	resistance[i]        = 0.3
	virulence[i]         = 0.0
	age[i]               = 0
	max_age[i]           = 8000
	agent_type[i]        = TYPE_PLANT
	flags[i]             = FLAG_ALIVE
	dead_timer[i]        = 0
	run_timer[i]         = randi_range(50, 150)
	spore_timer[i]       = 0
	brain_state[i]       = STATE_IDLE
	target_i[i]          = -1
	sense_radius[i]      = 0.0
	if i == count:
		count += 1
	_alive_count += 1
	return i


func spawn_fungi(px: float, py: float) -> int:
	var i: int = _find_free_slot()
	if i < 0:
		return -1
	pos_x[i]             = px
	pos_y[i]             = py
	dir_x[i]             = 0.0
	dir_y[i]             = 0.0
	energy[i]            = 0.8
	speed[i]             = 0.0
	size_arr[i]          = 2.0
	metabolism[i]        = 0.003
	division_threshold[i]= 1.8
	mutation_rate[i]     = 0.008
	resistance[i]        = 0.5
	virulence[i]         = 0.2
	age[i]               = 0
	max_age[i]           = 6000
	agent_type[i]        = TYPE_FUNGI
	flags[i]             = FLAG_ALIVE
	dead_timer[i]        = 0
	run_timer[i]         = randi_range(80, 200)
	spore_timer[i]       = 0
	brain_state[i]       = STATE_IDLE
	target_i[i]          = -1
	sense_radius[i]      = 80.0
	if i == count:
		count += 1
	_alive_count += 1
	return i


func kill(i: int) -> void:
	if flags[i] & FLAG_ALIVE == 0:
		return
	flags[i] &= ~FLAG_ALIVE
	_alive_count -= 1
	dead_timer[i] = DEAD_DECAY_TICKS
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	var cur: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	WorldGrid.set_cell_value(gx, gy, "nutrients", minf(cur + energy[i] * 0.3, 1.0))


func is_alive(i: int) -> bool:
	return (flags[i] & FLAG_ALIVE) != 0


func get_population_count() -> int:
	return _alive_count


func _rebuild_spatial() -> void:
	_spatial.clear()
	for i in count:
		if flags[i] & FLAG_ALIVE == 0:
			continue
		var cell: Vector2i = Vector2i(
			floori(pos_x[i] / SPATIAL_CELL),
			floori(pos_y[i] / SPATIAL_CELL)
		)
		if not _spatial.has(cell):
			_spatial[cell] = PackedInt32Array()
		_spatial[cell].append(i)


func get_agents_in_radius(px: float, py: float, radius: float) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	var r2: float = radius * radius
	var cell_radius: int = ceili(radius / SPATIAL_CELL)
	var cx: int = floori(px / SPATIAL_CELL)
	var cy: int = floori(py / SPATIAL_CELL)
	for dy in range(-cell_radius, cell_radius + 1):
		for dx in range(-cell_radius, cell_radius + 1):
			var cell: Vector2i = Vector2i(cx + dx, cy + dy)
			if not _spatial.has(cell):
				continue
			for i in _spatial[cell]:
				var ddx: float = pos_x[i] - px
				var ddy: float = pos_y[i] - py
				if ddx * ddx + ddy * ddy <= r2:
					result.append(i)
	return result


func _process(_delta: float) -> void:
	if _needs_compact:
		compact_dead()
		_needs_compact = false


func _on_tick(tick: int) -> void:
	_rebuild_spatial()
	_process_agents(tick)
	_needs_compact = true
	_dirty = true


func _process_agents(tick: int) -> void:
	var start: int = tick % TICK_STRIDE
	var i: int = start
	while i < count:
		var f: int = flags[i]
		if f & FLAG_ALIVE:
			if agent_type[i] == TYPE_BACTERIUM:
				_tick_bacterium(i)
			elif agent_type[i] == TYPE_PROTOZOA:
				_tick_protozoa(i)
			elif agent_type[i] == TYPE_PLANT:
				_tick_plant(i)
			elif agent_type[i] == TYPE_FUNGI:
				_tick_fungi(i)
			else:
				_tick_virus(i)
		i += TICK_STRIDE


func _tick_bacterium(i: int) -> void:
	age[i] += 1
	if age[i] > max_age[i]:
		kill(i)
		return
	if flags[i] & FLAG_SPORE:
		_tick_spore(i)
		return
	_consume_energy(i)
	if not is_alive(i):
		return
	_move_bacterium(i)
	_consume_nutrients(i)
	_check_sporulation(i)
	_check_division(i)


func _tick_spore(i: int) -> void:
	spore_timer[i] += 1
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	var nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	var temp: float = WorldGrid.get_cell_value(gx, gy, "temperature")
	if nutrients > 0.3 and temp >= 5.0 and spore_timer[i] > SPORE_MIN_TIMER:
		flags[i] &= ~FLAG_SPORE
		energy[i] = 0.3


func _consume_energy(i: int) -> void:
	energy[i] -= metabolism[i]
	if energy[i] <= 0.0:
		kill(i)


func _move_bacterium(i: int) -> void:
	run_timer[i] -= 1
	if run_timer[i] <= 0:
		_tumble(i)
	pos_x[i] += dir_x[i] * (speed[i] / 60.0)
	pos_y[i] += dir_y[i] * (speed[i] / 60.0)


func _tumble(i: int) -> void:
	var grad: Vector2 = _sample_gradient(i)
	if grad.length_squared() > 0.0001:
		var bias: float = clampf(grad.length() * 5.0, 0.0, 1.0)
		var dx: float = dir_x[i]
		var dy: float = dir_y[i]
		var gn: Vector2 = grad.normalized()
		var nx: float = lerpf(dx, gn.x, bias * 0.6)
		var ny: float = lerpf(dy, gn.y, bias * 0.6)
		var l: float = sqrt(nx * nx + ny * ny)
		dir_x[i] = nx / l
		dir_y[i] = ny / l
	else:
		var angle: float = randf() * TAU
		dir_x[i] = cos(angle)
		dir_y[i] = sin(angle)
	run_timer[i] = randi_range(30, 90)


func _sample_gradient(i: int) -> Vector2:
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	var r: int = 3
	return Vector2(
		WorldGrid.get_cell_value(gx + r, gy, "nutrients") - WorldGrid.get_cell_value(gx - r, gy, "nutrients"),
		WorldGrid.get_cell_value(gx, gy + r, "nutrients") - WorldGrid.get_cell_value(gx, gy - r, "nutrients")
	)


func _consume_nutrients(i: int) -> void:
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	var available: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	var uptake: float = minf(0.03, available)
	WorldGrid.set_cell_value(gx, gy, "nutrients", available - uptake)
	energy[i] = minf(energy[i] + uptake, 2.0)


func _check_sporulation(i: int) -> void:
	if not (flags[i] & FLAG_GRAM_POS):
		return
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	var nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	var temp: float = WorldGrid.get_cell_value(gx, gy, "temperature")
	if nutrients < 0.05 and temp < 5.0:
		flags[i] |= FLAG_SPORE
		spore_timer[i] = 0


func _check_division(i: int) -> void:
	if energy[i] < division_threshold[i]:
		return
	if _alive_count >= MAX_AGENTS:
		return
	var angle: float = randf() * TAU
	var child_genome: Dictionary = _mutate_genome_inline(i)
	var cost: float = division_threshold[i] * 0.6
	energy[i] -= cost * 0.5
	var ci: int = spawn_bacterium(
		pos_x[i] + cos(angle) * 4.0,
		pos_y[i] + sin(angle) * 4.0,
		child_genome
	)
	if ci >= 0:
		energy[ci] = cost * 0.5


func _mutate_genome_inline(i: int) -> Dictionary:
	var rate: float = mutation_rate[i]
	var child: Dictionary = {
		"move_speed":         speed[i] * (1.0 + randfn(0.0, 0.08) if randf() < rate else 1.0),
		"metabolism":         metabolism[i] * (1.0 + randfn(0.0, 0.08) if randf() < rate else 1.0),
		"division_threshold": division_threshold[i] * (1.0 + randfn(0.0, 0.08) if randf() < rate else 1.0),
		"mutation_rate":      mutation_rate[i] * (1.0 + randfn(0.0, 0.08) if randf() < rate else 1.0),
		"resistance":         resistance[i] * (1.0 + randfn(0.0, 0.08) if randf() < rate else 1.0),
		"virulence":          virulence[i] * (1.0 + randfn(0.0, 0.08) if randf() < rate else 1.0),
		"gram_positive":      not (flags[i] & FLAG_GRAM_POS == 0) if randf() < 0.001 else bool(flags[i] & FLAG_GRAM_POS),
		"max_age":            max_age[i],
		"size":               size_arr[i],
	}
	return child


func _tick_virus(i: int) -> void:
	age[i] += 1
	if age[i] >= max_age[i]:
		kill(i)
		return
	var angle: float = randf() * TAU
	dir_x[i] = cos(angle)
	dir_y[i] = sin(angle)
	pos_x[i] += dir_x[i] * (speed[i] * 0.3 / 60.0)
	pos_y[i] += dir_y[i] * (speed[i] * 0.3 / 60.0)
	_virus_infect(i)


func _virus_infect(i: int) -> void:
	var transmission_radius: float = virulence[i] * 66.7
	var targets: PackedInt32Array = get_agents_in_radius(pos_x[i], pos_y[i], transmission_radius)
	for j in targets:
		if j == i or not is_alive(j):
			continue
		if agent_type[j] != TYPE_BACTERIUM:
			continue
		if randf() < 0.02:
			var eff: float = 1.0 - resistance[j]
			if randf() > eff:
				continue
			energy[j] -= 0.05
			if energy[j] <= 0.0:
				kill(j)
			elif randf() < 0.1 * eff:
				kill(j)


func _tick_protozoa(i: int) -> void:
	age[i] += 1
	if age[i] > max_age[i]:
		kill(i)
		return
	energy[i] -= metabolism[i]
	if energy[i] <= 0.0:
		kill(i)
		return
	match brain_state[i]:
		STATE_IDLE:
			_protozoa_idle(i)
		STATE_SEEK:
			_protozoa_seek(i)
		STATE_HUNT:
			_protozoa_hunt(i)
		STATE_REPRODUCE:
			_protozoa_reproduce(i)


func _protozoa_idle(i: int) -> void:
	# Random walk, scan for prey
	run_timer[i] -= 1
	if run_timer[i] <= 0:
		var angle: float = randf() * TAU
		dir_x[i] = cos(angle)
		dir_y[i] = sin(angle)
		run_timer[i] = randi_range(20, 60)
	pos_x[i] += dir_x[i] * (speed[i] * 0.3 / 60.0)
	pos_y[i] += dir_y[i] * (speed[i] * 0.3 / 60.0)
	# Scan for nearby bacteria
	var prey: int = _find_prey(i)
	if prey >= 0:
		target_i[i] = prey
		brain_state[i] = STATE_HUNT
	elif energy[i] >= division_threshold[i]:
		brain_state[i] = STATE_REPRODUCE


func _protozoa_seek(i: int) -> void:
	# Move toward last known prey direction
	pos_x[i] += dir_x[i] * (speed[i] * 0.5 / 60.0)
	pos_y[i] += dir_y[i] * (speed[i] * 0.5 / 60.0)
	var prey: int = _find_prey(i)
	if prey >= 0:
		target_i[i] = prey
		brain_state[i] = STATE_HUNT
	else:
		run_timer[i] -= 1
		if run_timer[i] <= 0:
			brain_state[i] = STATE_IDLE


func _protozoa_hunt(i: int) -> void:
	var ti: int = target_i[i]
	# Validate target still alive
	if ti < 0 or ti >= count or not is_alive(ti) or agent_type[ti] != TYPE_BACTERIUM:
		target_i[i] = -1
		brain_state[i] = STATE_IDLE
		return
	# Move toward target
	var dx: float = pos_x[ti] - pos_x[i]
	var dy: float = pos_y[ti] - pos_y[i]
	var dist2: float = dx * dx + dy * dy
	if dist2 > 0.01:
		var inv: float = 1.0 / sqrt(dist2)
		dir_x[i] = dx * inv
		dir_y[i] = dy * inv
	pos_x[i] += dir_x[i] * (speed[i] / 60.0)
	pos_y[i] += dir_y[i] * (speed[i] / 60.0)
	# Eat on contact (distance < 12px)
	if dist2 < 144.0:
		energy[i] = minf(energy[i] + energy[ti] * 0.7, 4.0)
		kill(ti)
		target_i[i] = -1
		brain_state[i] = STATE_IDLE if energy[i] < division_threshold[i] else STATE_REPRODUCE
	elif dist2 > sense_radius[i] * sense_radius[i] * 4.0:
		# Lost target
		target_i[i] = -1
		brain_state[i] = STATE_SEEK
		run_timer[i] = 40


func _protozoa_reproduce(i: int) -> void:
	if _alive_count >= MAX_AGENTS:
		brain_state[i] = STATE_IDLE
		return
	var angle: float = randf() * TAU
	var ci: int = spawn_protozoa(
		pos_x[i] + cos(angle) * 10.0,
		pos_y[i] + sin(angle) * 10.0
	)
	if ci >= 0:
		energy[ci] = division_threshold[i] * 0.4
		energy[i] -= division_threshold[i] * 0.5
	brain_state[i] = STATE_IDLE


func _tick_plant(i: int) -> void:
	age[i] += 1
	if age[i] > max_age[i]:
		kill(i)
		return
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	# Photosynthesis: consume light + water, produce nutrients + oxygen
	var light: float = WorldGrid.get_cell_value(gx, gy, "light")
	var water: float = WorldGrid.get_cell_value(gx, gy, "water")
	if light > 0.3 and water > 0.2:
		var produced: float = light * 0.04
		energy[i] = minf(energy[i] + produced * 0.5, division_threshold[i] * 1.5)
		WorldGrid.set_cell_value(gx, gy, "nutrients",
			minf(WorldGrid.get_cell_value(gx, gy, "nutrients") + produced * 0.3, 1.0))
		WorldGrid.set_cell_value(gx, gy, "oxygen",
			minf(WorldGrid.get_cell_value(gx, gy, "oxygen") + produced * 0.2, 0.4))
		WorldGrid.set_cell_value(gx, gy, "water",
			maxf(water - produced * 0.1, 0.0))
	else:
		energy[i] -= metabolism[i]
		if energy[i] <= 0.0:
			kill(i)
			return
	# Spread: create a new plant nearby every run_timer ticks
	run_timer[i] -= 1
	if run_timer[i] <= 0:
		run_timer[i] = randi_range(100, 300)
		if energy[i] >= division_threshold[i] and _alive_count < MAX_AGENTS:
			var angle: float = randf() * TAU
			var dist: float = randf_range(16.0, 48.0)
			var ci: int = spawn_plant(
				pos_x[i] + cos(angle) * dist,
				pos_y[i] + sin(angle) * dist
			)
			if ci >= 0:
				energy[i] -= division_threshold[i] * 0.4
				energy[ci] = 0.5


func _tick_fungi(i: int) -> void:
	age[i] += 1
	if age[i] > max_age[i]:
		kill(i)
		return
	energy[i] -= metabolism[i]
	if energy[i] <= 0.0:
		kill(i)
		return
	var gx: int = int(pos_x[i] / WorldGrid.CELL_SIZE)
	var gy: int = int(pos_y[i] / WorldGrid.CELL_SIZE)
	# Decompose: consume dead organic matter (low nutrients = already consumed area,
	# fungi work on cadavers nearby)
	var local_nutrients: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
	# Absorb nutrients from soil
	var uptake: float = minf(0.02, local_nutrients * 0.3)
	WorldGrid.set_cell_value(gx, gy, "nutrients", local_nutrients - uptake)
	energy[i] = minf(energy[i] + uptake * 1.5, division_threshold[i] * 1.5)
	# Decompose nearby dead agents — recycle their energy back to soil
	run_timer[i] -= 1
	if run_timer[i] <= 0:
		run_timer[i] = randi_range(40, 100)
		_fungi_decompose(i)
	# Spread
	if energy[i] >= division_threshold[i] and _alive_count < MAX_AGENTS:
		var angle: float = randf() * TAU
		var dist: float = randf_range(8.0, 32.0)
		var ci: int = spawn_fungi(
			pos_x[i] + cos(angle) * dist,
			pos_y[i] + sin(angle) * dist
		)
		if ci >= 0:
			energy[i] -= division_threshold[i] * 0.5
			energy[ci] = 0.4


func _fungi_decompose(i: int) -> void:
	var r2: float = sense_radius[i] * sense_radius[i]
	var px: float = pos_x[i]
	var py: float = pos_y[i]
	for j in count:
		if flags[j] & FLAG_ALIVE:
			continue
		if dead_timer[j] <= 0:
			continue
		var dx: float = pos_x[j] - px
		var dy: float = pos_y[j] - py
		if dx * dx + dy * dy > r2:
			continue
		dead_timer[j] = maxi(dead_timer[j] - 10, 0)
		var gx: int = int(pos_x[j] / WorldGrid.CELL_SIZE)
		var gy: int = int(pos_y[j] / WorldGrid.CELL_SIZE)
		var cur: float = WorldGrid.get_cell_value(gx, gy, "nutrients")
		WorldGrid.set_cell_value(gx, gy, "nutrients", minf(cur + 0.05, 1.0))


func _find_prey(i: int) -> int:
	var r: float = sense_radius[i]
	var r2: float = r * r
	var px: float = pos_x[i]
	var py: float = pos_y[i]
	var best: int = -1
	var best_dist2: float = r2
	# Use spatial hash for efficiency
	var cell_radius: int = ceili(r / SPATIAL_CELL)
	var cx: int = floori(px / SPATIAL_CELL)
	var cy: int = floori(py / SPATIAL_CELL)
	for dy in range(-cell_radius, cell_radius + 1):
		for ddx in range(-cell_radius, cell_radius + 1):
			var cell: Vector2i = Vector2i(cx + ddx, cy + dy)
			if not _spatial.has(cell):
				continue
			for j in _spatial[cell]:
				if agent_type[j] != TYPE_BACTERIUM or not is_alive(j):
					continue
				var ddx2: float = pos_x[j] - px
				var ddy2: float = pos_y[j] - py
				var d2: float = ddx2 * ddx2 + ddy2 * ddy2
				if d2 < best_dist2:
					best_dist2 = d2
					best = j
	return best


func compact_dead() -> void:
	var i: int = 0
	while i < count:
		if flags[i] & FLAG_ALIVE:
			i += 1
			continue
		if dead_timer[i] > 0:
			dead_timer[i] -= 1
			i += 1
			continue
		# Swap with last and shrink
		var last: int = count - 1
		if i != last:
			_swap_agents(i, last)
		_clear_slot(last)
		count -= 1


func _swap_agents(a: int, b: int) -> void:
	var tmp_f: float
	tmp_f = pos_x[a]; pos_x[a] = pos_x[b]; pos_x[b] = tmp_f
	tmp_f = pos_y[a]; pos_y[a] = pos_y[b]; pos_y[b] = tmp_f
	tmp_f = dir_x[a]; dir_x[a] = dir_x[b]; dir_x[b] = tmp_f
	tmp_f = dir_y[a]; dir_y[a] = dir_y[b]; dir_y[b] = tmp_f
	tmp_f = energy[a]; energy[a] = energy[b]; energy[b] = tmp_f
	tmp_f = speed[a]; speed[a] = speed[b]; speed[b] = tmp_f
	tmp_f = size_arr[a]; size_arr[a] = size_arr[b]; size_arr[b] = tmp_f
	tmp_f = metabolism[a]; metabolism[a] = metabolism[b]; metabolism[b] = tmp_f
	tmp_f = division_threshold[a]; division_threshold[a] = division_threshold[b]; division_threshold[b] = tmp_f
	tmp_f = mutation_rate[a]; mutation_rate[a] = mutation_rate[b]; mutation_rate[b] = tmp_f
	tmp_f = resistance[a]; resistance[a] = resistance[b]; resistance[b] = tmp_f
	tmp_f = virulence[a]; virulence[a] = virulence[b]; virulence[b] = tmp_f
	var tmp_i: int
	tmp_i = age[a]; age[a] = age[b]; age[b] = tmp_i
	tmp_i = max_age[a]; max_age[a] = max_age[b]; max_age[b] = tmp_i
	tmp_i = agent_type[a]; agent_type[a] = agent_type[b]; agent_type[b] = tmp_i
	tmp_i = flags[a]; flags[a] = flags[b]; flags[b] = tmp_i
	tmp_i = dead_timer[a]; dead_timer[a] = dead_timer[b]; dead_timer[b] = tmp_i
	tmp_i = run_timer[a]; run_timer[a] = run_timer[b]; run_timer[b] = tmp_i
	tmp_i = spore_timer[a]; spore_timer[a] = spore_timer[b]; spore_timer[b] = tmp_i
	tmp_i = brain_state[a]; brain_state[a] = brain_state[b]; brain_state[b] = tmp_i
	tmp_i = target_i[a];    target_i[a]    = target_i[b];    target_i[b]    = tmp_i
	tmp_f = sense_radius[a]; sense_radius[a] = sense_radius[b]; sense_radius[b] = tmp_f


func _clear_slot(i: int) -> void:
	pos_x[i] = 0.0; pos_y[i] = 0.0
	dir_x[i] = 1.0; dir_y[i] = 0.0
	energy[i] = 0.0; speed[i] = 0.0; size_arr[i] = 0.0
	metabolism[i] = 0.0; division_threshold[i] = 0.0
	mutation_rate[i] = 0.0; resistance[i] = 0.0; virulence[i] = 0.0
	age[i] = 0; max_age[i] = 0; agent_type[i] = 0
	flags[i] = 0; dead_timer[i] = 0; run_timer[i] = 0; spore_timer[i] = 0
	brain_state[i] = 0; target_i[i] = -1; sense_radius[i] = 0.0
