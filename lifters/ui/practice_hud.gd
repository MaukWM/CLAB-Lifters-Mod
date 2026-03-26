# Shows "PRACTICE MODE" label at top-center when practice mode is active.
extends Node

var _practice_mode: Node
var _label: Label

func setup(practice_mode: Node) -> void:
	_practice_mode = practice_mode
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not _practice_mode.is_active:
		if is_instance_valid(_label):
			_label.hide()
		return

	if Globals.GAME_HUD_NODE == null:
		return

	if not is_instance_valid(_label):
		_create_label()

	_label.visible = Globals.GAME_HUD_NODE.visible

func _create_label() -> void:
	_label = Label.new()
	_label.name = "PracticeModeLabel"
	_label.text = "PRACTICE MODE"
	_label.label_settings = load("res://theme_stuff/label_settings/gameplay_label_score.tres")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 16.0
	_label.offset_left = -200.0
	_label.offset_right = 200.0
	Globals.GAME_HUD_NODE.add_child(_label)
	print("Lifters: Practice mode HUD label added.")
