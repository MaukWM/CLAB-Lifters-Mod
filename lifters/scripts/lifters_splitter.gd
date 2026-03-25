# Split detection logic. Polls game state each physics tick and fires splits.
extends Node

var _config: Node
var _livesplit: Node

var _prev_power: float = 0.0
var _prev_frog_count: int = 0
var _prev_finish_queued: bool = false
var _prev_game_state = null
var _active: bool = false

func setup(livesplit: Node, config: Node) -> void:
	_livesplit = livesplit
	_config = config
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(_delta: float) -> void:
	if not _config.get_setting("autosplit.enabled"):
		return

	# Only track when in game
	var game_state = Globals.CURRENT_GAME_STATE
	if game_state != Globals.GAME_STATE.IN_GAME:
		_prev_game_state = game_state
		return

	# Entering IN_GAME: start tracking
	if _prev_game_state != Globals.GAME_STATE.IN_GAME:
		_active = true
		_prev_power = Globals.MAIN_NODE.game_power
		_prev_frog_count = SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"].size()
		_prev_finish_queued = false
		_livesplit.start_or_split()
		print("Lifters Splitter: Entered game, split sent.")
		_prev_game_state = game_state
		return

	_prev_game_state = game_state

	if not _active:
		return

	# Read current state
	var current_power: float = Globals.MAIN_NODE.game_power
	var current_frog_count: int = SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"].size()
	var current_finish_queued: bool = Globals.MAIN_NODE.finish_game_queued
	var current_time: float = SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"]

	# Send game time every tick
	_livesplit.set_game_time(current_time)

	# Power interval splits
	if _config.get_setting("autosplit.emit_on_power"):
		var interval = _config.get_setting("autosplit.power_interval")
		if interval > 0.0:
			var prev_step = floor(_prev_power / interval)
			var curr_step = floor(current_power / interval)
			if curr_step > prev_step:
				_livesplit.start_or_split()
				print("Lifters Splitter: Power split at ", current_power)

	# Frog splits
	if _config.get_setting("autosplit.emit_on_frog"):
		if current_frog_count > _prev_frog_count:
			_livesplit.start_or_split()
			print("Lifters Splitter: Frog split (", current_frog_count, " total).")

	# Boulder lift split
	if _config.get_setting("autosplit.emit_on_boulder_lift"):
		if current_finish_queued and not _prev_finish_queued:
			_livesplit.start_or_split()
			print("Lifters Splitter: Boulder lift split!")

	# Update previous state
	_prev_power = current_power
	_prev_frog_count = current_frog_count
	_prev_finish_queued = current_finish_queued

