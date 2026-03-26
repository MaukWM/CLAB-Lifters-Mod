# Practice mode state and keybind handler.
extends Node

var is_active: bool = false
var _was_in_game: bool = false
var _save_state: Dictionary = {}
var _hud: Node

func setup(hud: Node) -> void:
	_hud = hud

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
		_save_state = {}
		print("Lifters: Practice mode deactivated (returned to menu).")

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or Globals.CURRENT_GAME_STATE != Globals.GAME_STATE.IN_GAME:
		return
	if not (event is InputEventKey and event.pressed):
		return

	var shift = event.shift_pressed
	match event.keycode:
		KEY_F1:
			_save_state_capture()
		KEY_F2:
			_save_state_load()
		KEY_F5:
			_adjust_power(-0.01 if shift else -0.20)
		KEY_F6:
			_adjust_power(0.01 if shift else 0.20)
		KEY_F8:
			_reset_items()

func _adjust_power(delta: float) -> void:
	var new_power = clamp(Globals.MAIN_NODE.game_power + delta, 0.0, 4.0)
	Globals.MAIN_NODE.game_power = new_power
	_recalc_abilities()
	print("Lifters: Power set to %.2f" % new_power)

func _recalc_abilities() -> void:
	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if not player:
		return
	player.float_ability_unlocked = false
	player.jump_extend_ability_unlocked = false
	player.ice_platform_ability_unlocked = false
	player.navi_active = false
	player._determine_max_energy(true)

# --- Save State ---

func _save_state_capture() -> void:
	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if not player:
		return

	_save_state = {
		"position": player.global_position,
		"velocity": player.velocity,
		"energy": player.energy,
		"game_power": Globals.MAIN_NODE.game_power,
		"game_score": Globals.MAIN_NODE.game_score,
		"time_spent": SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"],
		"items_collected": SaveFileManager.LEVEL_SAVE_CONTENT["items_collected"].duplicate(),
		"frogs_collected": SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"].duplicate(),
		"counter_power": SaveFileManager.LEVEL_SAVE_CONTENT["counter_power_items_collected"],
		"counter_score": SaveFileManager.LEVEL_SAVE_CONTENT["counter_score_items_collected"],
		"counter_special": SaveFileManager.LEVEL_SAVE_CONTENT["counter_special_items_collected"],
	}
	if _hud:
		_hud.show_feedback("STATE SAVED")
	print("Lifters: State saved at %s" % str(player.global_position))

func _save_state_load() -> void:
	if _save_state.is_empty():
		print("Lifters: No save state to load.")
		return

	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if not player:
		return

	# Restore player
	player.global_position = _save_state["position"]
	player.velocity = _save_state["velocity"]

	# Restore game state
	Globals.MAIN_NODE.game_power = _save_state["game_power"]
	Globals.MAIN_NODE.game_score = _save_state["game_score"]
	SaveFileManager.LEVEL_SAVE_CONTENT["time_spent_seconds"] = _save_state["time_spent"]
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_power_items_collected"] = _save_state["counter_power"]
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_score_items_collected"] = _save_state["counter_score"]
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_special_items_collected"] = _save_state["counter_special"]

	# Restore collection state: first respawn everything, then remove saved-as-collected
	SaveFileManager.LEVEL_SAVE_CONTENT["items_collected"] = []
	SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"] = []
	_walk_entities(Globals.LEVEL_NODE)

	# Now set the saved collection arrays and remove those items from the world
	SaveFileManager.LEVEL_SAVE_CONTENT["items_collected"] = _save_state["items_collected"].duplicate()
	SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"] = _save_state["frogs_collected"].duplicate()
	_remove_collected_entities(Globals.LEVEL_NODE)

	# Restore abilities and energy
	_recalc_abilities()
	player.energy = _save_state["energy"]

	if _hud:
		_hud.show_feedback("STATE LOADED")
	print("Lifters: State loaded.")

func _remove_collected_entities(node: Node) -> void:
	var script_path := ""
	if node.get_script():
		script_path = node.get_script().resource_path

	if script_path in [
		"res://entities/item_score.gd",
		"res://entities/item_power.gd",
		"res://entities/item_special.gd"
	]:
		var item_child = node.get_node_or_null("Item")
		if item_child and is_instance_valid(item_child):
			var item_id = node.entity.get("id", -1)
			if item_id in SaveFileManager.LEVEL_SAVE_CONTENT["items_collected"]:
				item_child.queue_free()
	elif script_path == "res://entities/frog.gd":
		var frog_child = node.get_node_or_null("frog")
		if frog_child and is_instance_valid(frog_child):
			var frog_id = node.entity.get("id", -1)
			if frog_id in SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"]:
				frog_child.queue_free()

	for child in node.get_children():
		_remove_collected_entities(child)

# --- Item Reset ---

var _item_scene: PackedScene = preload("res://scenes/entities/item/item.tscn")
var _frog_entity_scene: PackedScene = preload("res://entities/frog.tscn")

func _reset_items() -> void:
	SaveFileManager.LEVEL_SAVE_CONTENT["items_collected"] = []
	SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"] = []
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_power_items_collected"] = 0
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_score_items_collected"] = 0
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_special_items_collected"] = 0

	Globals.MAIN_NODE.game_power = 0.0
	Globals.MAIN_NODE.game_score = 0
	_recalc_abilities()

	var counts := _walk_entities(Globals.LEVEL_NODE)
	print("Lifters: Items reset (%d items, %d frogs respawned)." % [counts[0], counts[1]])

func _walk_entities(node: Node) -> Array:
	var counts := [0, 0]
	var script_path := ""
	if node.get_script():
		script_path = node.get_script().resource_path

	if script_path in [
		"res://entities/item_score.gd",
		"res://entities/item_power.gd",
		"res://entities/item_special.gd"
	]:
		if not _has_valid_child(node, "Item"):
			_respawn_item(node, script_path)
			counts[0] += 1
	elif script_path == "res://entities/frog.gd":
		if not _has_valid_child(node, "frog"):
			_respawn_frog(node)
			counts[1] += 1

	for child in node.get_children():
		var child_counts := _walk_entities(child)
		counts[0] += child_counts[0]
		counts[1] += child_counts[1]

	return counts

func _has_valid_child(parent: Node, child_name: String) -> bool:
	var child = parent.get_node_or_null(child_name)
	return child != null and is_instance_valid(child)

func _respawn_item(entity_node: Node, script_path: String) -> void:
	var item = _item_scene.instantiate()

	var is_big: bool = entity_node.entity.get("is_big", false)
	var is_floating: bool = entity_node.entity.get("is_floating", false)
	var item_id: int = entity_node.entity.get("id", -1)

	if script_path == "res://entities/item_power.gd":
		item.item_type = item.ITEM_TYPE.ITEM_POWER_BIG if is_big else item.ITEM_TYPE.ITEM_POWER
	elif script_path == "res://entities/item_score.gd":
		item.item_type = item.ITEM_TYPE.ITEM_SCORE_BIG if is_big else item.ITEM_TYPE.ITEM_SCORE
	elif script_path == "res://entities/item_special.gd":
		item.item_type = item.ITEM_TYPE.ITEM_SPECIAL

	item.is_floating = is_floating
	item.item_id = item_id

	entity_node.add_child(item)

func _respawn_frog(entity_node: Node) -> void:
	var parent = entity_node.get_parent()
	var fresh = _frog_entity_scene.instantiate()

	fresh.entity = entity_node.entity
	fresh.transform = entity_node.transform

	parent.add_child(fresh)
	entity_node.queue_free()

	var frog_child = fresh.get_node_or_null("frog")
	if frog_child:
		frog_child.item_id = fresh.entity.get("id", -1)
	fresh.set_frog_skin(fresh.frog_skin)
