# Shows "PRACTICE MODE" label and speedometer when practice mode is active.
extends Node

var _practice_mode: Node
var _label: Label
var _speed_label: Label

func setup(practice_mode: Node) -> void:
	_practice_mode = practice_mode
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not _practice_mode.is_active:
		if is_instance_valid(_label):
			_label.hide()
		if is_instance_valid(_speed_label):
			_speed_label.hide()
		return

	if Globals.GAME_HUD_NODE == null:
		return

	if not is_instance_valid(_label):
		_create_labels()

	_label.visible = Globals.GAME_HUD_NODE.visible
	_speed_label.visible = Globals.GAME_HUD_NODE.visible

	if _speed_label.visible:
		_update_speed()

func _update_speed() -> void:
	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if not player:
		return
	var vel: Vector3 = player.velocity
	var h_speed := Vector2(vel.x, vel.z).length()
	_speed_label.text = "%.1f u/s" % h_speed

func _create_labels() -> void:
	var label_settings = load("res://theme_stuff/label_settings/gameplay_label_score.tres")

	_label = Label.new()
	_label.name = "PracticeModeLabel"
	_label.text = "PRACTICE MODE"
	_label.label_settings = label_settings
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 16.0
	_label.offset_left = -200.0
	_label.offset_right = 200.0
	Globals.GAME_HUD_NODE.add_child(_label)

	_speed_label = Label.new()
	_speed_label.name = "SpeedLabel"
	_speed_label.text = "0.0 u/s"
	_speed_label.label_settings = label_settings
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_speed_label.anchor_left = 1.0
	_speed_label.anchor_right = 1.0
	_speed_label.anchor_top = 1.0
	_speed_label.anchor_bottom = 1.0
	_speed_label.offset_left = -200.0
	_speed_label.offset_right = 26.0
	_speed_label.offset_top = -60.0
	_speed_label.offset_bottom = -8.0
	_speed_label.scale = Vector2(0.7, 0.7)
	Globals.GAME_HUD_NODE.add_child(_speed_label)

	print("Lifters: Practice mode HUD labels added.")
