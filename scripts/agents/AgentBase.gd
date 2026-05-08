class_name AgentBase
extends Node2D

signal died

var energy: float = 1.0
var age: int = 0
var max_age: int = 3000
var speed: float = 30.0
var size: float = 1.0
var alive: bool = true
var genome: Dictionary = {}
# Ticks avant suppression du cadavre (10 ticks/s × 30s = 300)
var dead_ticks_remaining: int = 0

var _direction: Vector2 = Vector2.RIGHT


func _tick(_tick_num: int) -> void:
	pass


func _move() -> void:
	pass


func consume_energy(amount: float) -> void:
	energy -= amount
	if energy <= 0.0:
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	dead_ticks_remaining = 300
	_restitute_nutrients()
	died.emit()


func get_grid_pos() -> Vector2i:
	return WorldGrid.world_to_grid(global_position)


func _restitute_nutrients() -> void:
	var gp: Vector2i = get_grid_pos()
	var current: float = WorldGrid.get_cell_value(gp.x, gp.y, "nutrients")
	WorldGrid.set_cell_value(gp.x, gp.y, "nutrients", minf(current + energy * 0.3, 1.0))
