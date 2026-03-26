# Split detection logic. Polls game state each physics tick and fires splits.
extends Node

var _config: Node
var _livesplit: Node

var _prev_power: float = 0.0
var _prev_score: int = 0
var _prev_frog_count: int = 0
var _prev_finish_queued: bool = false
var _prev_game_state = null
var _active: bool = false
var _started: bool = false
var _paused: bool = false
var _finished: bool = false

func setup(livesplit: Node, config: Node) -> void:
	_livesplit = livesplit
	_config = config
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(_delta: float) -> void:
	if not _config.get_setting("autosplit.enabled"):
		return

	var game_state = Globals.CURRENT_GAME_STATE

	# Keep sending game time every tick so LiveSplit stays in sync (stop after boulder lift)
	if _started and _active and not _finished:
		var current_time: float = SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"]
		_livesplit.set_game_time(current_time)

	# Pause/unpause LiveSplit's internal clock to prevent flicker
	if game_state == Globals.GAME_STATE.PAUSE_MENU and not _paused and _active:
		_livesplit.pause_game_time()
		_paused = true
	elif game_state == Globals.GAME_STATE.IN_GAME and _paused:
		_livesplit.unpause_game_time()
		_paused = false

	# Deactivate when returning to main menu
	if game_state == Globals.GAME_STATE.MAIN_MENU and _active:
		_active = false
		_started = false
		_paused = false
		_finished = false

	# Only process splits/detection when in game
	if game_state != Globals.GAME_STATE.IN_GAME:
		_prev_game_state = game_state
		return

	# Entering IN_GAME from main menu (not from unpause)
	if _prev_game_state == Globals.GAME_STATE.MAIN_MENU:
		_active = true
		_started = false
		_finished = false
		_prev_power = Globals.MAIN_NODE.game_power
		_prev_score = SaveFileManager.LEVEL_SAVE_CONTENT["counter_score_items_collected"]
		_prev_frog_count = SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"].size()
		_prev_finish_queued = false
		print("Lifters Splitter: Entered game, waiting for lockout to end.")
		_prev_game_state = game_state
		return

	_prev_game_state = game_state

	if not _active:
		return

	# Read current state
	var current_power: float = Globals.MAIN_NODE.game_power
	var current_score: int = SaveFileManager.LEVEL_SAVE_CONTENT["counter_score_items_collected"]
	var current_frog_count: int = SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"].size()
	var current_finish_queued: bool = Globals.MAIN_NODE.finish_game_queued
	var current_time: float = SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"]

	# Wait for game timer to start ticking (lockout ended)
	if not _started and current_time > 0.0:
		_started = true
		_livesplit.start_or_split()
		print("Lifters Splitter: Game timer started, split sent.")

	if not _started:
		return

	# Power interval splits
	if _config.get_setting("autosplit.emit_on_power"):
		var interval = _config.get_setting("autosplit.power_interval")
		if interval > 0.0:
			var prev_step = floor(_prev_power / interval)
			var curr_step = floor(current_power / interval)
			if curr_step > prev_step:
				_livesplit.start_or_split()
				print("Lifters Splitter: Power split at ", current_power)

	# Score interval splits
	if _config.get_setting("autosplit.emit_on_score"):
		var interval = _config.get_setting("autosplit.score_interval")
		if interval > 0:
			var prev_step = _prev_score / interval
			var curr_step = current_score / interval
			if curr_step > prev_step:
				_livesplit.start_or_split()
				print("Lifters Splitter: Score split at ", current_score)

	# Frog splits
	if _config.get_setting("autosplit.emit_on_frog"):
		if current_frog_count > _prev_frog_count:
			_livesplit.start_or_split()
			print("Lifters Splitter: Frog split (", current_frog_count, " total).")

	# Boulder lift split — freeze timer after this
	if _config.get_setting("autosplit.emit_on_boulder_lift"):
		if current_finish_queued and not _prev_finish_queued:
			_livesplit.set_game_time(current_time)
			_livesplit.pause_game_time()
			_livesplit.start_or_split()
			_finished = true
			print("Lifters Splitter: Boulder lift split! Timer frozen.")

	# Update previous state
	_prev_power = current_power
	_prev_score = current_score
	_prev_frog_count = current_frog_count
	_prev_finish_queued = current_finish_queued
