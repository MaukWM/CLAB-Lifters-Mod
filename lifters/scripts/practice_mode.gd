# Practice mode state. Other systems check is_active to alter behavior.
extends Node

var is_active: bool = false
var _was_in_game: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not is_active:
		return
	var state = Globals.CURRENT_GAME_STATE
	if state == Globals.GAME_STATE.IN_GAME:
		_was_in_game = true
	elif state == Globals.GAME_STATE.MAIN_MENU and _was_in_game:
		is_active = false
		_was_in_game = false
		print("Lifters: Practice mode deactivated (returned to menu).")
