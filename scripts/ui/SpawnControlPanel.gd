extends Control

@onready var _btn_bacteria: Button  = $Panel/VBox/BtnBacteria
@onready var _btn_virus: Button     = $Panel/VBox/BtnVirus
@onready var _btn_protozoa: Button  = $Panel/VBox/BtnProtozoa
@onready var _btn_plant: Button     = $Panel/VBox/BtnPlant
@onready var _btn_fungi: Button     = $Panel/VBox/BtnFungi

@onready var _vis_bacteria: Button  = $Panel/VBox/VisBacteria
@onready var _vis_virus: Button     = $Panel/VBox/VisVirus
@onready var _vis_protozoa: Button  = $Panel/VBox/VisProtozoa
@onready var _vis_plant: Button     = $Panel/VBox/VisPlant
@onready var _vis_fungi: Button     = $Panel/VBox/VisFungi

var _sim_renderer: Node = null


func _ready() -> void:
	_btn_bacteria.toggled.connect(_on_bacteria_toggled)
	_btn_virus.toggled.connect(_on_virus_toggled)
	_btn_protozoa.toggled.connect(_on_protozoa_toggled)
	_btn_plant.toggled.connect(_on_plant_toggled)
	_btn_fungi.toggled.connect(_on_fungi_toggled)

	_vis_bacteria.toggled.connect(func(p): _set_vis(AgentPool.TYPE_BACTERIUM, p))
	_vis_virus.toggled.connect(func(p): _set_vis(AgentPool.TYPE_VIRUS, p))
	_vis_protozoa.toggled.connect(func(p): _set_vis(AgentPool.TYPE_PROTOZOA, p))
	_vis_plant.toggled.connect(func(p): _set_vis(AgentPool.TYPE_PLANT, p))
	_vis_fungi.toggled.connect(func(p): _set_vis(AgentPool.TYPE_FUNGI, p))

	await get_tree().process_frame
	_sim_renderer = get_tree().get_first_node_in_group("sim_renderer")


func _set_vis(type_idx: int, visible: bool) -> void:
	if _sim_renderer == null:
		_sim_renderer = get_tree().get_first_node_in_group("sim_renderer")
	if _sim_renderer != null:
		_sim_renderer.type_visible[type_idx] = visible
		AgentPool._dirty = true


func _on_bacteria_toggled(pressed: bool) -> void:
	ChunkSpawner.spawn_bacteria_enabled = pressed
	_btn_bacteria.text = ("● " if pressed else "○ ") + "Bacteria"


func _on_virus_toggled(pressed: bool) -> void:
	ChunkSpawner.spawn_virus_enabled = pressed
	_btn_virus.text = ("● " if pressed else "○ ") + "Virus"


func _on_protozoa_toggled(pressed: bool) -> void:
	ChunkSpawner.spawn_protozoa_enabled = pressed
	_btn_protozoa.text = ("● " if pressed else "○ ") + "Protozoa"


func _on_plant_toggled(pressed: bool) -> void:
	ChunkSpawner.spawn_plant_enabled = pressed
	_btn_plant.text = ("● " if pressed else "○ ") + "Plants"


func _on_fungi_toggled(pressed: bool) -> void:
	ChunkSpawner.spawn_fungi_enabled = pressed
	_btn_fungi.text = ("● " if pressed else "○ ") + "Fungi"
