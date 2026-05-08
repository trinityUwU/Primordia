class_name AgentRenderer
extends Node2D

const COLOR_GRAM_POS: Color = Color(0.4, 0.7, 1.0, 0.9)
const COLOR_GRAM_NEG: Color = Color(1.0, 0.45, 0.2, 0.9)
const COLOR_SPORE: Color = Color(0.55, 0.55, 0.55, 0.85)
const COLOR_VIRUS: Color = Color(1.0, 0.25, 0.25, 0.65)
const COLOR_OUTLINE: Color = Color(0.0, 0.0, 0.0, 0.6)

const BACTERIUM_BASE_RADIUS: float = 5.0
const SPORE_RADIUS: float = 3.0
const VIRUS_RADIUS: float = 4.0


func _draw() -> void:
	if not is_instance_valid(PopulationManager):
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	var cull_rect: Rect2 = Rect2(camera.global_position - half, half * 2.0).grow(50.0)
	var agents: Array = PopulationManager.get_all_agents()
	for agent in agents:
		if not cull_rect.has_point(agent.global_position):
			continue
		if not agent.alive:
			_draw_corpse(agent)
			continue
		if PopulationManager.is_bacterium(agent):
			_draw_bacterium(agent)
		elif PopulationManager.is_virus(agent):
			_draw_virus(agent)


func _draw_corpse(agent: Node2D) -> void:
	var alpha: float = clampf(float(agent.dead_ticks_remaining) / 300.0, 0.0, 1.0)
	var radius: float = BACTERIUM_BASE_RADIUS * clampf(agent.size, 0.5, 2.0)
	var color: Color = Color(0.4, 0.35, 0.3, alpha * 0.7)
	draw_circle(agent.global_position, radius, color)


func _draw_bacterium(b: Node2D) -> void:
	var pos: Vector2 = b.global_position
	if b.is_spore():
		draw_circle(pos, SPORE_RADIUS, COLOR_SPORE)
		draw_arc(pos, SPORE_RADIUS, 0.0, TAU, 8, COLOR_OUTLINE, 0.8)
		return
	var radius: float = BACTERIUM_BASE_RADIUS * clampf(b.size, 0.5, 2.0)
	var gram_pos: bool = b.genome.get("gram_positive", true)
	var base_color: Color = COLOR_GRAM_POS if gram_pos else COLOR_GRAM_NEG
	draw_circle(pos, radius, base_color)
	draw_arc(pos, radius, 0.0, TAU, 12, COLOR_OUTLINE, 0.8)


func _draw_virus(v: Node2D) -> void:
	var pos: Vector2 = v.global_position
	_draw_pentagon(pos, VIRUS_RADIUS, COLOR_VIRUS)


func _draw_pentagon(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i in 5:
		var angle: float = (TAU / 5.0) * i - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
