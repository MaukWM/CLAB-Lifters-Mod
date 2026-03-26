# Watches for the title menu and injects the PRACTICE button.
extends Node

var _practice_mode: Node
var _injected: bool = false

func setup(practice_mode: Node) -> void:
	_practice_mode = practice_mode

func _process(_delta: float) -> void:
	if Globals.MENU_NODE == null:
		_injected = false
		return

	var title_menu = _find_title_menu()
	if title_menu and not _injected:
		_inject_practice_button(title_menu)
		_injected = true
	elif not title_menu:
		_injected = false

func _find_title_menu() -> Node:
	for child in Globals.MENU_NODE.get_children():
		if child.name == "TitleMenu":
			return child
	return null

func _inject_practice_button(menu: Node) -> void:
	print("Lifters: Found title menu, injecting Practice button...")

	var button = Button.new()
	button.name = "ButtonPractice"
	button.text = "PRACTICE"
	button.theme = load("res://theme_stuff/themes/UITheme.tres")
	button.add_theme_font_size_override("font_size", 64)
	button.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.7, 0.88, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.7, 0.88, 1.0))
	button.custom_minimum_size = Vector2(0, 66)
	button.disabled = true
	menu.add_child(button)

	# Position with anchors (centered like the other buttons)
	button.layout_mode = 1
	button.anchors_preset = -1
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.5675
	button.anchor_bottom = 0.5675
	button.offset_left = -91.5
	button.offset_right = 91.5
	button.offset_top = -33.0
	button.offset_bottom = 33.0
	button.grow_horizontal = 2
	button.grow_vertical = 2

	# Respace buttons for 5 items: Start 0.46, Practice 0.575, Options 0.69, Credits 0.8, Quit 0.889
	var btn_start = menu.get_node("%ButtonStart")
	var btn_options = menu.get_node("%ButtonOptions")
	var btn_credits = menu.get_node("%ButtonCredits")
	var btn_quit = menu.get_node("%ButtonQuit")

	# Respace 5 buttons evenly: 0.46 → 0.89 with equal ~0.1075 gaps
	btn_start.anchor_top = 0.46
	btn_start.anchor_bottom = 0.46
	# Practice at 0.5675 (set above)
	btn_options.anchor_top = 0.675
	btn_options.anchor_bottom = 0.675
	btn_credits.anchor_top = 0.7825
	btn_credits.anchor_bottom = 0.7825
	btn_quit.anchor_top = 0.89
	btn_quit.anchor_bottom = 0.89

	# Rewire focus chain: Start → Practice → Options → Credits → Quit
	btn_start.focus_neighbor_bottom = button.get_path()
	button.focus_neighbor_top = btn_start.get_path()
	button.focus_neighbor_bottom = btn_options.get_path()
	btn_options.focus_neighbor_top = button.get_path()

	# Enable button when Start is enabled (hook into the same enable timing)
	if not btn_start.disabled:
		button.disabled = false
	else:
		# Poll until Start is enabled, then enable Practice too
		var timer = func():
			while btn_start.disabled:
				await get_tree().process_frame
			button.disabled = false
		timer.call()

	# Connect signals
	button.pressed.connect(_on_practice_pressed.bind(menu))
	button.focus_entered.connect(func():
		var sg = menu.get_node_or_null("%SelectGraphic")
		if sg:
			sg.target_y = button.global_position.y
	)
	button.mouse_entered.connect(func(): button.grab_focus())

	print("Lifters: Practice button injected!")

func _on_practice_pressed(menu: Node) -> void:
	_practice_mode.is_active = true
	print("Lifters: Practice mode activated, starting game...")
	Globals.MAIN_NODE.on_start_game()
