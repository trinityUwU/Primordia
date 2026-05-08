class_name Virus
extends "res://scripts/agents/AgentBase.gd"

var r0: float = 2.5
var incubation_ticks: int = 50
var lethality: float = 0.1
var mutation_rate: float = 0.05
var transmission_radius: float = 20.0
var transmission_prob: float = 0.02
var lifetime_ticks: int = 100

var _ticks_alive: int = 0


func _ready() -> void:
	max_age = lifetime_ticks
	size = 0.4
	energy = 1.0
	_direction = Vector2.from_angle(randf() * TAU)


func _tick(_tick_num: int) -> void:
	if not alive:
		return
	_ticks_alive += 1
	if _ticks_alive >= lifetime_ticks:
		die()
		return
	_move()
	_attempt_transmissions()


func _move() -> void:
	_direction = Vector2.from_angle(randf() * TAU)
	global_position += _direction * (speed * 0.3 / 60.0)


func _attempt_transmissions() -> void:
	var nearby: Array = PopulationManager.get_agents_in_radius(
		global_position, transmission_radius
	)
	for target in nearby:
		if target == self or not target.alive:
			continue
		if randf() < transmission_prob:
			infect(target)


func infect(target: Node2D) -> void:
	var resistance: float = target.genome.get("resistance", 0.0)
	var effective_prob: float = 1.0 - resistance
	if randf() > effective_prob:
		return
	target.consume_energy(0.05)
	if randf() < lethality * (1.0 - resistance):
		target.die()


