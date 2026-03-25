# Lifters settings sub-menu. Built programmatically to match the game's UI style.
extends "res://scenes/UI/menus/base_menu_with_transitions.gd"

var _config: Node
var _select_graphic: Node
var _power_interval_label: Label
var _power_splits_label: Label
var _power_interval_slider: HSlider
var _power_row: HBoxContainer
var _splits_row: HBoxContainer

func setup(config: Node) -> void:
	_config = config

func _ready() -> void:
	# Full-screen root
	anchors_preset = 15
	anchor_right = 1.0
	anchor_bottom = 1.0
	pivot_offset = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ui_theme = load("res://theme_stuff/themes/UITheme.tres")
	var ui_theme_small = load("res://theme_stuff/themes/UITheme_50h.tres")
	var label_settings = load("res://theme_stuff/label_settings/ui_label_default.tres")
	var label_settings_big = load("res://theme_stuff/label_settings/ui_label_super_big.tres")
	var header_bg_tex = load("res://sprites/ui/header_background.png")
	var pillar_bg_tex = load("res://sprites/ui/background_pillar.png")
	var pillar_script = load("res://scenes/UI/menus/misc_elements/bg_pillar.gd")
	var select_graphic_scene = load("res://scenes/UI/menus/misc_elements/select_graphic.tscn")

	# Background pillar
	var pillar = NinePatchRect.new()
	pillar.texture = pillar_bg_tex
	pillar.offset_left = 191.0
	pillar.offset_top = -1024.0
	pillar.offset_right = 960.0
	pillar.offset_bottom = 64.0
	pillar.scale = Vector2(2, 2)
	pillar.patch_margin_left = 55
	pillar.patch_margin_right = 55
	pillar.axis_stretch_vertical = 1
	pillar.set_script(pillar_script)
	add_child(pillar)

	# Select graphic (focus indicator)
	_select_graphic = select_graphic_scene.instantiate()
	_select_graphic.layout_mode = 1
	_select_graphic.anchor_top = 0.3
	_select_graphic.anchor_bottom = 0.3
	_select_graphic.offset_left = -760.0
	_select_graphic.offset_top = -32.68
	_select_graphic.offset_right = 760.0
	_select_graphic.offset_bottom = 33.32
	add_child(_select_graphic)

	# Header
	var header_container = CenterContainer.new()
	header_container.layout_mode = 1
	header_container.anchor_left = 0.5
	header_container.anchor_top = 0.126
	header_container.anchor_right = 0.5
	header_container.anchor_bottom = 0.126
	header_container.offset_left = -303.0
	header_container.offset_top = -90.0
	header_container.offset_right = 303.0
	header_container.offset_bottom = 90.0
	add_child(header_container)

	var header_bg = TextureRect.new()
	header_bg.texture = header_bg_tex
	header_bg.layout_mode = 2
	header_container.add_child(header_bg)

	var header_label = Label.new()
	header_label.text = "LIFTERS MOD"
	header_label.label_settings = label_settings_big
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_label.layout_mode = 2
	header_container.add_child(header_label)

	# Scrollable options area
	var margin = MarginContainer.new()
	margin.layout_mode = 1
	margin.anchor_left = 0.15
	margin.anchor_top = 0.28
	margin.anchor_right = 0.85
	margin.anchor_bottom = 0.85
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var options = VBoxContainer.new()
	options.name = "OptionsContainer"
	options.layout_mode = 2
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 24)
	scroll.add_child(options)

	# --- General section ---
	_add_section_label(options, "GENERAL", ui_theme, label_settings)
	var disable_save = _add_toggle(options, "Disable Saving", "disable_save", ui_theme, label_settings)

	# --- Story section ---
	_add_section_label(options, "STORY", ui_theme, label_settings)
	var skip_intro = _add_toggle(options, "Skip Intro", "skip_intro_story", ui_theme, label_settings)
	var skip_endgame = _add_toggle(options, "Skip Ending", "skip_endgame_story", ui_theme, label_settings)

	# --- Autosplit section ---
	_add_section_label(options, "AUTOSPLIT", ui_theme, label_settings)
	var autosplit_enabled = _add_toggle(options, "Enable Autosplitting", "autosplit.enabled", ui_theme, label_settings)
	var emit_frog = _add_toggle(options, "Split on Frog", "autosplit.emit_on_frog", ui_theme, label_settings)
	var emit_power = _add_toggle(options, "Split on Power", "autosplit.emit_on_power", ui_theme, label_settings)

	# Power interval slider row
	_power_row = HBoxContainer.new()
	_power_row.add_theme_constant_override("separation", 16)
	_power_row.layout_mode = 2
	options.add_child(_power_row)

	var interval_label = Label.new()
	interval_label.text = "  Power Interval"
	interval_label.label_settings = label_settings
	interval_label.custom_minimum_size = Vector2(350, 64)
	interval_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_power_row.add_child(interval_label)

	_power_interval_slider = HSlider.new()
	_power_interval_slider.min_value = 0.01
	_power_interval_slider.max_value = 3.99
	_power_interval_slider.step = 0.01
	_power_interval_slider.value = _config.get_setting("autosplit.power_interval")
	_power_interval_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_power_interval_slider.custom_minimum_size = Vector2(200, 0)
	_power_row.add_child(_power_interval_slider)

	_power_interval_label = Label.new()
	_power_interval_label.text = "%.2f" % _power_interval_slider.value
	_power_interval_label.label_settings = label_settings
	_power_interval_label.custom_minimum_size = Vector2(128, 0)
	_power_interval_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_interval_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_power_row.add_child(_power_interval_label)

	# Split count info row
	_splits_row = HBoxContainer.new()
	_splits_row.layout_mode = 2
	options.add_child(_splits_row)

	_power_splits_label = Label.new()
	_power_splits_label.label_settings = label_settings
	_splits_row.add_child(_power_splits_label)
	_update_splits_label()

	var emit_boulder = _add_toggle(options, "Split on Boulder Lift", "autosplit.emit_on_boulder_lift", ui_theme, label_settings)

	# Update power row visibility
	_update_power_row_state()

	# --- Back button ---
	var back_btn = Button.new()
	back_btn.name = "ButtonBack"
	back_btn.text = "BACK"
	back_btn.theme = ui_theme
	back_btn.custom_minimum_size = Vector2(0, 66)
	back_btn.layout_mode = 1
	back_btn.anchor_left = 0.5
	back_btn.anchor_right = 0.5
	back_btn.anchor_top = 0.888
	back_btn.anchor_bottom = 0.889
	back_btn.offset_left = -91.5
	back_btn.offset_right = 91.5
	back_btn.offset_top = -32.0
	back_btn.offset_bottom = 32.88
	back_btn.grow_horizontal = 2
	back_btn.grow_vertical = 2
	add_child(back_btn)
	back_button = back_btn

	back_btn.pressed.connect(_on_back_pressed)
	back_btn.focus_entered.connect(func(): _select_graphic.target_y = back_btn.global_position.y)
	back_btn.mouse_entered.connect(func(): back_btn.grab_focus())

	# Connect slider
	_power_interval_slider.value_changed.connect(_on_power_interval_changed)
	_power_interval_slider.focus_entered.connect(func(): _select_graphic.target_y = _power_interval_slider.global_position.y)
	_power_interval_slider.mouse_entered.connect(func(): _power_interval_slider.grab_focus())

	# React to autosplit toggle to dim/enable power rows
	_config.setting_changed.connect(_on_setting_changed)

	# Grab initial focus
	skip_intro.grab_focus.call_deferred()

	super._ready()

func _add_section_label(parent: VBoxContainer, text: String, theme: Theme, lbl_settings: LabelSettings) -> void:
	var sep = HSeparator.new()
	sep.layout_mode = 2
	sep.add_theme_constant_override("separation", 16)
	parent.add_child(sep)

	var label = Label.new()
	label.text = text
	label.label_settings = lbl_settings
	label.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	label.layout_mode = 2
	parent.add_child(label)

func _add_toggle(parent: VBoxContainer, label_text: String, setting_key: String, theme: Theme, lbl_settings: LabelSettings) -> CheckBox:
	var row = HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.label_settings = lbl_settings
	label.custom_minimum_size = Vector2(512, 64)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var checkbox = CheckBox.new()
	checkbox.theme = theme
	checkbox.custom_minimum_size = Vector2(450, 64)
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkbox.button_pressed = _config.get_setting(setting_key)
	checkbox.toggled.connect(func(enabled): _config.set_setting(setting_key, enabled))
	checkbox.focus_entered.connect(func(): _select_graphic.target_y = checkbox.global_position.y)
	checkbox.mouse_entered.connect(func(): checkbox.grab_focus())
	row.add_child(checkbox)

	return checkbox

func _on_power_interval_changed(value: float) -> void:
	_config.set_setting("autosplit.power_interval", value)
	_power_interval_label.text = "%.2f" % value
	_update_splits_label()

func _update_splits_label() -> void:
	var interval = _config.get_setting("autosplit.power_interval")
	var count = int(4.0 / interval)
	if fmod(4.0, interval) > 0.001:
		count += 1
	_power_splits_label.text = "  (Produces %d splits)" % count

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "autosplit.emit_on_power":
		_update_power_row_state()

func _update_power_row_state() -> void:
	var enabled = _config.get_setting("autosplit.emit_on_power")
	_power_row.modulate.a = 1.0 if enabled else 0.4
	_power_interval_slider.editable = enabled
	_splits_row.modulate.a = 1.0 if enabled else 0.4

func _on_back_pressed() -> void:
	if !transition_tween:
		_config.save()
		_create_transition_tween(true, _switch_to_options)

func _switch_to_options() -> void:
	var options_menu = load("res://scenes/UI/menus/options/options_menu.tscn")
	Globals.MENU_NODE.add_child(options_menu.instantiate())
	queue_free()
