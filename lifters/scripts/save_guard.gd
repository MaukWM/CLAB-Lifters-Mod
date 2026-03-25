# Prevents level saves from persisting when disable_save is enabled.
# Resets PREVIOUS_LEVEL_SAVE_EXISTS on startup and on every return to main menu.
extends Node

var _config: Node
var _connected: bool = false

func setup(config: Node) -> void:
	_config = config

func _ready() -> void:
	GlobalEventBus.game_state_changed.connect(_on_game_state_changed)
	# On startup: wipe level save so title menu shows NEW GAME
	if _config.get_setting("disable_save"):
		SaveFileManager.delete_level_state()
		print("Lifters: Save disabled — level state wiped.")

func _on_game_state_changed(new_state) -> void:
	if new_state == Globals.GAME_STATE.MAIN_MENU and _config.get_setting("disable_save"):
		SaveFileManager.delete_level_state()
		print("Lifters: Save disabled — level state wiped on return to menu.")
