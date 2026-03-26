# Practice mode state and keybind handler.
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

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or Globals.CURRENT_GAME_STATE != Globals.GAME_STATE.IN_GAME:
		return
	if not (event is InputEventKey and event.pressed):
		return

	var shift = event.shift_pressed
	match event.keycode:
		KEY_F5:
			_adjust_power(-0.01 if shift else -0.20)
		KEY_F6:
			_adjust_power(0.01 if shift else 0.20)

func _adjust_power(delta: float) -> void:
	var new_power = clamp(Globals.MAIN_NODE.game_power + delta, 0.0, 4.0)
	Globals.MAIN_NODE.game_power = new_power

	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if player:
		# Reset ability flags so _determine_max_energy can recalculate from scratch
		player.float_ability_unlocked = false
		player.jump_extend_ability_unlocked = false
		player.ice_platform_ability_unlocked = false
		player.navi_active = false
		player._determine_max_energy(true)

	print("Lifters: Power set to %.2f" % new_power)
