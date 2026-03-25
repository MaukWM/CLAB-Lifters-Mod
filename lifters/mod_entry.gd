# Lifters — Autoload entry point (override.cfg + autoload_prepend)
extends Node

const MOD_DIR = "res://lifters/"

func _init() -> void:
	print("Lifters: Mod initializing...")

func _ready() -> void:
	# UI: Options menu button injector
	var options_injector = Node.new()
	options_injector.name = "OptionsInjector"
	options_injector.set_script(load(MOD_DIR + "ui/options_injector.gd"))
	add_child(options_injector)

	# TODO: Config singleton (lifters_config.gd)
	# TODO: LiveSplit TCP client (livesplit_client.gd)
	# TODO: Split detector (lifters_splitter.gd)
	# TODO: Intro skip watcher (intro_skip_watcher.gd)
	# TODO: Lifters settings menu (lifters_menu.gd)

	print("Lifters: All systems ready.")
