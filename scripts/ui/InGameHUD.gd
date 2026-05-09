extends CanvasLayer

const COLOR_ACCENT: Color = Color(0.31, 0.76, 0.97, 1.0)   # #4fc3f7
const COLOR_DIM: Color = Color(0.4, 0.4, 0.4, 1.0)

@onready var _autosave_label: Label = $AutosaveStatus
@onready var _saving_flash: Label = $SavingFlash

var _flash_tween: Tween


func _ready() -> void:
	_autosave_label.modulate = COLOR_DIM
	_saving_flash.modulate.a = 0.0
	SaveManager.autosave_triggered.connect(_on_autosave_triggered)


func _process(_delta: float) -> void:
	_update_autosave_label()


func _update_autosave_label() -> void:
	var elapsed: float = SaveManager.get_time_since_last_save()
	if SaveManager.get_current_slot_id() == "":
		_autosave_label.visible = false
		return
	_autosave_label.visible = true
	_autosave_label.text = "● Autosaved %s ago" % _format_elapsed(elapsed)


func _on_autosave_triggered(_slot_id: String) -> void:
	_play_saving_flash()


func _play_saving_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_saving_flash.text = "Saving..."
	_saving_flash.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.6)
	_flash_tween.tween_property(_saving_flash, "modulate:a", 0.0, 0.9)


func _format_elapsed(seconds: float) -> String:
	var s: int = int(seconds)
	if s < 60:
		return "%02d:%02d" % [0, s]
	return "%02d:%02d" % [s / 60, s % 60]
