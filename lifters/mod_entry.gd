# Lifters — Autoload entry point (override.cfg + autoload_prepend)
extends Node

const MOD_DIR = "res://lifters/"

var config: Node

func _init() -> void:
	print("Lifters: Mod initializing...")

func _ready() -> void:
	# Config singleton (must be first — everything else depends on it)
	config = Node.new()
	config.name = "LiftersConfig"
	config.set_script(load(MOD_DIR + "scripts/lifters_config.gd"))
	add_child(config)

	# UI: Options menu button injector
	var options_injector = Node.new()
	options_injector.name = "OptionsInjector"
	options_injector.set_script(load(MOD_DIR + "ui/options_injector.gd"))
	add_child(options_injector)

	# UI: Timer display patch (centisecond precision)
	var timer_patch = Node.new()
	timer_patch.name = "TimerDisplayPatch"
	timer_patch.set_script(load(MOD_DIR + "ui/timer_display_patch.gd"))
	add_child(timer_patch)

	# Story skip watcher
	var story_watcher = Node.new()
	story_watcher.name = "StorySkipWatcher"
	story_watcher.set_script(load(MOD_DIR + "scripts/story_skip_watcher.gd"))
	add_child(story_watcher)
	story_watcher.setup(config)

	# Save guard (disable saving for speedruns)
	var save_guard = Node.new()
	save_guard.name = "SaveGuard"
	save_guard.set_script(load(MOD_DIR + "scripts/save_guard.gd"))
	add_child(save_guard)
	save_guard.setup(config)

	# LiveSplit TCP client
	var livesplit = Node.new()
	livesplit.name = "LiveSplitClient"
	livesplit.set_script(load(MOD_DIR + "scripts/livesplit_client.gd"))
	add_child(livesplit)
	livesplit.setup(config)

	# Split detector
	var splitter = Node.new()
	splitter.name = "Splitter"
	splitter.set_script(load(MOD_DIR + "scripts/lifters_splitter.gd"))
	add_child(splitter)
	splitter.setup(livesplit, config)

	print("Lifters: All systems ready.")
