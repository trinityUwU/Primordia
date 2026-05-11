extends Control

# Scale bar — shows real-world distance represented by 100 screen pixels
# 1 world unit = 1 μm

const BAR_SCREEN_PX: float = 100.0

@onready var _label_dist: Label  = $VBox/LabelDist
@onready var _label_ctx: Label   = $VBox/LabelCtx
@onready var _bar: ColorRect     = $VBox/Bar

var _camera: Camera2D


func _ready() -> void:
	await get_tree().process_frame
	_camera = get_tree().get_first_node_in_group("main_camera")
	if _camera and _camera.has_signal("zoom_changed"):
		_camera.zoom_changed.connect(_on_zoom_changed)
	_refresh()


func _on_zoom_changed(_z: float) -> void:
	_refresh()


func _refresh() -> void:
	if _camera == null:
		return
	var wu_per_px: float = 1.0 / _camera.zoom.x   # μm per screen pixel
	var wu_total: float = wu_per_px * BAR_SCREEN_PX  # μm represented by bar

	_label_dist.text = _format_distance(wu_total)
	_label_ctx.text  = _context_label(wu_total)


func _format_distance(um: float) -> String:
	if um < 1.0:
		return "%.0f nm" % (um * 1000.0)
	elif um < 1000.0:
		return "%.1f μm" % um
	elif um < 1_000_000.0:
		return "%.2f mm" % (um / 1000.0)
	elif um < 1_000_000_000.0:
		return "%.2f m" % (um / 1_000_000.0)
	else:
		return "%.2f km" % (um / 1_000_000_000.0)


func _context_label(um: float) -> String:
	if um < 1.0:        return "Nanométrique"
	elif um < 100.0:    return "Microscopique"
	elif um < 10_000.0: return "Cellulaire"
	elif um < 1_000_000.0: return "Millimétrique"
	elif um < 100_000_000.0: return "Macroscopique"
	else:               return "Paysage"
