extends Node

const MAX_AGENTS: int = 2000
const INITIAL_BACTERIA: int = 50

var _agents: Array = []
var _agent_layer: Node2D = null
var _bacterium_script: GDScript = null
var _virus_script: GDScript = null


func _ready() -> void:
	load("res://scripts/agents/AgentBase.gd")
	_bacterium_script = load("res://scripts/agents/Bacterium.gd")
	_virus_script = load("res://scripts/agents/Virus.gd")
	SimulationClock.tick_processed.connect(_on_tick)
	call_deferred("_spawn_initial")


func _spawn_initial() -> void:
	_agent_layer = get_tree().get_root().find_child("AgentLayer", true, false)
	var w: float = WorldGrid.GRID_WIDTH * WorldGrid.CELL_SIZE
	var h: float = WorldGrid.GRID_HEIGHT * WorldGrid.CELL_SIZE
	for i in INITIAL_BACTERIA:
		var pos: Vector2 = Vector2(randf() * w, randf() * h)
		spawn_bacterium(pos)


func spawn_bacterium(pos: Vector2, genome: Dictionary = {}) -> Node2D:
	if _agents.size() >= MAX_AGENTS or _bacterium_script == null:
		return null
	var b: Node2D = _bacterium_script.new()
	b.global_position = pos
	if not genome.is_empty():
		b.genome = genome
	_register_agent(b)
	return b


func spawn_virus(pos: Vector2) -> Node2D:
	if _agents.size() >= MAX_AGENTS or _virus_script == null:
		return null
	var v: Node2D = _virus_script.new()
	v.global_position = pos
	_register_agent(v)
	return v


func _register_agent(agent: Node2D) -> void:
	_agents.append(agent)
	agent.died.connect(_on_agent_died)
	if _agent_layer != null:
		_agent_layer.add_child(agent)
	else:
		add_child(agent)


func _on_agent_died() -> void:
	pass


func _on_tick(tick_num: int) -> void:
	_process_agents(tick_num)
	_purge_dead()
	_request_redraw()


func _process_agents(tick_num: int) -> void:
	for agent in _agents:
		if agent.alive:
			agent._tick(tick_num)


func _purge_dead() -> void:
	var alive: Array = []
	for agent in _agents:
		if agent.alive:
			alive.append(agent)
		elif is_instance_valid(agent):
			agent.queue_free()
	_agents = alive


func _request_redraw() -> void:
	if _agent_layer == null:
		return
	var renderer: Node = _agent_layer.get_node_or_null("AgentRenderer")
	if renderer != null:
		renderer.queue_redraw()


func get_population_count() -> int:
	return _agents.size()


func get_agents_in_radius(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var radius_sq: float = radius * radius
	for agent in _agents:
		if agent.alive and agent.global_position.distance_squared_to(pos) <= radius_sq:
			result.append(agent)
	return result


func get_all_agents() -> Array:
	return _agents


func is_bacterium(agent: Node2D) -> bool:
	return agent.get_script() == _bacterium_script


func is_virus(agent: Node2D) -> bool:
	return agent.get_script() == _virus_script
