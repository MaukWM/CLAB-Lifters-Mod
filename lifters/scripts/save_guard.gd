# Prevents level saves from persisting when disable_save is enabled.
# Wipes level state on startup and ensures NEW GAME on every return to menu.
extends Node

var _config: Node

func setup(config: Node) -> void:
	_config = config

func _ready() -> void:
	if _config.get_setting("disable_save"):
		SaveFileManager.delete_level_state()
		Globals.MAIN_NODE.reset_game_variables()
		print("Lifters: Save disabled — full wipe on startup.")

func _process(_delta: float) -> void:
	if not _config.get_setting("disable_save"):
		return

	# Only wipe when the title menu is actually showing — not during transient
	# MAIN_MENU states (e.g. clear_level() during end-game sequence).
	if Globals.CURRENT_GAME_STATE == Globals.GAME_STATE.MAIN_MENU and _is_title_menu_visible():
		if SaveFileManager.PREVIOUS_LEVEL_SAVE_EXISTS:
			SaveFileManager.delete_level_state()
			Globals.MAIN_NODE.reset_game_variables()
			print("Lifters: Save disabled — level state and game variables wiped.")

		# Also fix the title menu button text if it shows CONTINUE
		for child in Globals.MENU_NODE.get_children():
			if child.name == "TitleMenu":
				var btn = child.get_node_or_null("%ButtonStart")
				if btn and btn.text != TranslationServer.translate("M_NEW_GAME"):
					btn.text = TranslationServer.translate("M_NEW_GAME")

func _is_title_menu_visible() -> bool:
	if not Globals.MENU_NODE:
		return false
	for child in Globals.MENU_NODE.get_children():
		if child.name == "TitleMenu":
			return true
	return false
