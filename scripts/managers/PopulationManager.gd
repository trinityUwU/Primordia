extends Node

var _agents: Array = []
var _agent_layer: Node2D = null
var _bacterium_script: GDScript = null
var _virus_script: GDScript = null


func _ready() -> void:
	load("res://scripts/agents/AgentBase.gd")
	_bacterium_script = load("res://scripts/agents/Bacterium.gd")
	_virus_script = load("res://scripts/agents/Virus.gd")
	SimulationClock.tick_processed.connect(_on_tick)
	call_deferred("_init_agent_layer")


func _init_agent_layer() -> void:
	_agent_layer = get_tree().get_root().find_child("AgentLayer", true, false)


func spawn_bacterium(pos: Vector2, genome: Dictionary = {}) -> Node2D:
	if _bacterium_script == null:
		return null
	var b: Node2D = _bacterium_script.new()
	b.global_position = pos
	if not genome.is_empty():
		b.genome = genome
	_register_agent(b)
	return b


func spawn_virus(pos: Vector2) -> Node2D:
	if _virus_script == null:
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


# Stagger: chaque agent tique 1 fois sur TICK_STRIDE ticks pour étaler la charge.
const TICK_STRIDE: int = 2

func _process_agents(tick_num: int) -> void:
	var count: int = _agents.size()
	if count == 0:
		return
	var start: int = tick_num % TICK_STRIDE
	var i: int = start
	while i < count:
		var agent = _agents[i]
		if agent.alive:
			agent._tick(tick_num)
		i += TICK_STRIDE


func _purge_dead() -> void:
	var remaining: Array = []
	for agent in _agents:
		if not is_instance_valid(agent):
			continue
		if agent.alive:
			remaining.append(agent)
		elif agent.dead_ticks_remaining > 0:
			agent.dead_ticks_remaining -= 1
			remaining.append(agent)
		else:
			agent.queue_free()
	_agents = remaining


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
