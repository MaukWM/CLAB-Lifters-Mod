# Patches the game's ClockTimeLabel to show centiseconds (HH:MM:SS.cc).
# Applies to both the pause screen stat widget and the end screen stat widget.
# Controlled by the "precise_timer" setting.
extends Node

var _config: Node
var _pause_patched: bool = false
var _endscreen_patched: bool = false

func setup(config: Node) -> void:
	_config = config
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not _config or not _config.get_setting("precise_timer"):
		return

	# Patch pause screen timer
	if Globals.MENU_NODE:
		var options_menu = _find_options_menu()
		if options_menu and not _pause_patched:
			_try_patch_pause(options_menu)
		elif not options_menu:
			_pause_patched = false

	# Patch end screen timer
	if Globals.STORY_PARENT_NODE and not _endscreen_patched:
		_try_patch_endscreen()
	elif Globals.STORY_PARENT_NODE == null or Globals.STORY_PARENT_NODE.get_child_count() == 0:
		_endscreen_patched = false

func _find_options_menu() -> Node:
	for child in Globals.MENU_NODE.get_children():
		if child.name == "OptionsMenu":
			return child
	return null

func _try_patch_pause(menu: Node) -> void:
	if not get_tree().paused:
		return
	var container = menu.get_node_or_null("%StatWidgetContainer")
	if container == null:
		return
	for child in container.get_children():
		_patch_label(child)
	_pause_patched = true

func _try_patch_endscreen() -> void:
	for child in Globals.STORY_PARENT_NODE.get_children():
		var container = child.get_node_or_null("%StatWidgetContainer")
		if container == null:
			continue
		for widget in container.get_children():
			_patch_label(widget)
		_endscreen_patched = true

func _patch_label(widget: Node) -> void:
	var label = widget.get_node_or_null("%ClockTimeLabel")
	if label == null:
		return
	var time_seconds: float = SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"]
	label.text = _format_time_cs(time_seconds)
	if label.custom_minimum_size.x < 320:
		label.custom_minimum_size.x = 320
	print("Lifters: Timer patched → %s" % label.text)

func _format_time_cs(time_seconds: float) -> String:
	var total_ms := int(time_seconds * 1000.0)
	var cs := int((total_ms % 1000) / 10)
	var seconds := int((total_ms / 1000) % 60)
	var minutes := int((total_ms / 60000) % 60)
	var hours := int(total_ms / 3600000)
	return "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, cs]
