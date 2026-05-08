extends Control

@onready var _btn_bacteria: Button = $Panel/VBox/BtnBacteria
@onready var _btn_virus: Button = $Panel/VBox/BtnVirus
@onready var _btn_protozoa: Button = $Panel/VBox/BtnProtozoa
@onready var _btn_plant: Button = $Panel/VBox/BtnPlant
@onready var _btn_fungi: Button = $Panel/VBox/BtnFungi


func _ready() -> void:
	_btn_bacteria.toggled.connect(_on_bacteria_toggled)
	_btn_virus.toggled.connect(_on_virus_toggled)
	_btn_protozoa.toggled.connect(_on_protozoa_toggled)
	_btn_plant.toggled.connect(_on_plant_toggled)
	_btn_fungi.toggled.connect(_on_fungi_toggled)


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
