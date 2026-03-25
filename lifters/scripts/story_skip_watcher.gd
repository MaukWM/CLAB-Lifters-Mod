# Watches STORY_PARENT_NODE for story scenes and skips them based on config.
extends Node

var _config: Node
var _did_skip: bool = false

func setup(config: Node) -> void:
	_config = config
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Globals.STORY_PARENT_NODE == null:
		return

	if Globals.STORY_PARENT_NODE.get_child_count() == 0:
		_did_skip = false
		return

	if _did_skip:
		return

	for child in Globals.STORY_PARENT_NODE.get_children():
		var is_end = child.get("is_end_game_story")
		if is_end == null:
			continue

		if not is_end and _config.get_setting("skip_intro_story"):
			print("Lifters: Skipping intro story...")
			_did_skip = true
			child.queue_free()
			Globals.MAIN_NODE.on_start_game(false)
			return

		if is_end and _config.get_setting("skip_endgame_story"):
			print("Lifters: Skipping ending story, jumping to results screen...")
			_did_skip = true
			child.showing_end_game_image = true
			child.get_node("%StoryPanels").modulate.a = 0.0
			Globals.MUSIC_PLAYER.play_music(MusicPlayer.MUSIC.STORY_END, false)
			return
