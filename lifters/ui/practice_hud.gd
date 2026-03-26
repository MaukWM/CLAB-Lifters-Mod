# Shows "PRACTICE MODE" label, speedometer, keybind reference, and feedback when practice mode is active.
extends Node

var _practice_mode: Node
var _label: Label
var _speed_label: Label
var _keybinds_label: Label
var _feedback_label: Label
var _feedback_tween: Tween

func setup(practice_mode: Node) -> void:
	_practice_mode = practice_mode
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not _practice_mode.is_active:
		if is_instance_valid(_label):
			_label.hide()
		if is_instance_valid(_speed_label):
			_speed_label.hide()
		if is_instance_valid(_keybinds_label):
			_keybinds_label.hide()
		if is_instance_valid(_feedback_label):
			_feedback_label.hide()
		return

	if Globals.GAME_HUD_NODE == null:
		return

	if not is_instance_valid(_label):
		_create_labels()

	var vis = Globals.GAME_HUD_NODE.visible
	_label.visible = vis
	_speed_label.visible = vis
	_keybinds_label.visible = get_tree().paused

	if vis:
		_update_speed()

func show_feedback(text: String) -> void:
	if not is_instance_valid(_feedback_label):
		return
	_feedback_label.text = text
	_feedback_label.modulate.a = 1.0
	_feedback_label.show()
	if _feedback_tween:
		_feedback_tween.kill()
	_feedback_tween = get_tree().create_tween()
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 1.0).set_delay(0.5)

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

	_keybinds_label = Label.new()
	_keybinds_label.name = "KeybindsLabel"
	_keybinds_label.text = "F1  Save State\nF2  Load State\nF5/F6  Power ±0.20\nShift+F5/F6  ±0.01\nF8  Reset Items"
	_keybinds_label.label_settings = label_settings
	_keybinds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_keybinds_label.anchor_left = 0.0
	_keybinds_label.anchor_right = 0.0
	_keybinds_label.anchor_top = 1.0
	_keybinds_label.anchor_bottom = 1.0
	_keybinds_label.offset_left = 140.0
	_keybinds_label.offset_right = 640.0
	_keybinds_label.offset_top = -250.0
	_keybinds_label.offset_bottom = -110.0
	_keybinds_label.scale = Vector2(0.5, 0.5)
	Globals.GAME_HUD_NODE.add_child(_keybinds_label)

	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.label_settings = label_settings
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_feedback_label.offset_top = 80.0
	_feedback_label.offset_left = -300.0
	_feedback_label.offset_right = 300.0
	var feedback_settings = label_settings.duplicate()
	feedback_settings.font_size = 40
	_feedback_label.label_settings = feedback_settings
	_feedback_label.modulate.a = 0.0
	Globals.GAME_HUD_NODE.add_child(_feedback_label)

	print("Lifters: Practice mode HUD labels added.")
