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
		KEY_F8:
			_reset_items()

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

var _item_scene: PackedScene = preload("res://scenes/entities/item/item.tscn")
var _frog_entity_scene: PackedScene = preload("res://entities/frog.tscn")

func _reset_items() -> void:
	# Clear collection tracking
	SaveFileManager.LEVEL_SAVE_CONTENT["items_collected"] = []
	SaveFileManager.LEVEL_SAVE_CONTENT["frogs_collected"] = []
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_power_items_collected"] = 0
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_score_items_collected"] = 0
	SaveFileManager.LEVEL_SAVE_CONTENT["counter_special_items_collected"] = 0

	# Reset game power and score
	Globals.MAIN_NODE.game_power = 0.0
	Globals.MAIN_NODE.game_score = 0

	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if player:
		player.float_ability_unlocked = false
		player.jump_extend_ability_unlocked = false
		player.ice_platform_ability_unlocked = false
		player.navi_active = false
		player._determine_max_energy(true)

	# Walk the level tree for VMF entity parents that lost their child
	var counts := _walk_entities(Globals.LEVEL_NODE)

	print("Lifters: Items reset (%d items, %d frogs respawned)." % [counts[0], counts[1]])

func _walk_entities(node: Node) -> Array:
	var counts := [0, 0]  # [items, frogs]
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
	# Replace the entire frog entity with a fresh instance
	var parent = entity_node.get_parent()
	var fresh = _frog_entity_scene.instantiate()

	# Copy entity data from the old node
	fresh.entity = entity_node.entity
	fresh.transform = entity_node.transform

	# Swap: add fresh, remove old
	parent.add_child(fresh)
	entity_node.queue_free()

	# Configure the fresh frog child
	var frog_child = fresh.get_node_or_null("frog")
	if frog_child:
		frog_child.item_id = fresh.entity.get("id", -1)
	fresh.set_frog_skin(fresh.frog_skin)
