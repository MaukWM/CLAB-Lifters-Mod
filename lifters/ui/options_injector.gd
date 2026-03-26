# Watches for the options menu and injects the LIFTERS MOD button.
extends Node

var _button_injected: bool = false
var _endscreen_patched: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Globals.MENU_NODE == null:
		_button_injected = false
		return

	var options_menu = _find_options_menu()
	if options_menu and not _button_injected:
		_inject_lifters_button(options_menu)
		_button_injected = true
	elif not options_menu:
		_button_injected = false

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

func _inject_lifters_button(menu: Node) -> void:
	print("Lifters: Found options menu, injecting button...")

	var button = Button.new()
	button.name = "ButtonLifters"
	button.text = "LIFTERS MOD"
	button.theme = load("res://theme_stuff/themes/UITheme.tres")
	button.add_theme_font_size_override("font_size", 64)
	button.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.7, 0.88, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.7, 0.88, 1.0))
	button.custom_minimum_size = Vector2(0, 66)
	menu.add_child(button)

	# Position with anchors (same pattern as other buttons)
	button.layout_mode = 1
	button.anchors_preset = -1
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.806
	button.anchor_bottom = 0.806
	button.offset_left = -111.5
	button.offset_right = 111.5
	button.offset_top = -33.0
	button.offset_bottom = 33.0
	button.grow_horizontal = 2
	button.grow_vertical = 2

	# Respace all buttons to fit 7 items evenly
	var btn_audio = menu.get_node("%ButtonAudio")
	var btn_controls = menu.get_node("%ButtonControls")
	var btn_gameplay = menu.get_node("%ButtonGameplay")
	var btn_language = menu.get_node("%MenuButtonLanguage")
	var btn_back = menu.get_node("%ButtonBack")

	# Graphics stays at 0.296
	btn_audio.anchor_top = 0.398
	btn_audio.anchor_bottom = 0.398
	btn_controls.anchor_top = 0.500
	btn_controls.anchor_bottom = 0.500
	btn_gameplay.anchor_top = 0.602
	btn_gameplay.anchor_bottom = 0.602
	btn_language.anchor_top = 0.704
	btn_language.anchor_bottom = 0.704
	# Lifters at 0.806 (set above)
	# Back stays at 0.907

	# Rewire focus chain: Language → Lifters → Back
	btn_gameplay.focus_neighbor_bottom = btn_language.get_path()
	btn_language.focus_neighbor_top = btn_gameplay.get_path()
	btn_language.focus_neighbor_bottom = button.get_path()
	button.focus_neighbor_top = btn_language.get_path()
	button.focus_neighbor_bottom = btn_back.get_path()
	btn_back.focus_neighbor_top = button.get_path()

	# Connect signals
	button.pressed.connect(_on_button_lifters_pressed)
	button.focus_entered.connect(func(): menu.get_node("%SelectGraphic").target_y = button.global_position.y)
	button.mouse_entered.connect(func(): button.grab_focus())

	print("Lifters: Button injected!")

	# Patch timer label to show centiseconds if paused
	_try_patch_timer(menu)

func _try_patch_timer(menu: Node) -> void:
	if not get_tree().paused:
		return
	var container = menu.get_node_or_null("%StatWidgetContainer")
	if container == null:
		return
	for child in container.get_children():
		var label = child.get_node_or_null("%ClockTimeLabel")
		if label:
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

func _try_patch_endscreen() -> void:
	for child in Globals.STORY_PARENT_NODE.get_children():
		var container = child.get_node_or_null("%StatWidgetContainer")
		if container == null:
			continue
		for widget in container.get_children():
			var label = widget.get_node_or_null("%ClockTimeLabel")
			if label:
				var time_seconds: float = SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"]
				label.text = _format_time_cs(time_seconds)
				if label.custom_minimum_size.x < 320:
					label.custom_minimum_size.x = 320
				_endscreen_patched = true
				print("Lifters: End screen timer patched → %s" % label.text)

func _on_button_lifters_pressed() -> void:
	print("Lifters: Opening Lifters settings menu...")
	var config = get_parent().get_node("LiftersConfig")
	var menu_script = load("res://lifters/ui/lifters_menu.gd")
	var menu = Control.new()
	menu.set_script(menu_script)
	menu.setup(config)
	Globals.MENU_NODE.add_child(menu)
	# Remove the current options menu (same pattern as game's menu transitions)
	var options_menu = _find_options_menu()
	if options_menu:
		options_menu.queue_free()
