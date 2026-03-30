# Practice mode state and keybind handler.
extends Node

const NUM_SLOTS := 4

var is_active: bool = false
var _was_in_game: bool = false
var _save_slots: Array[Dictionary] = []
var _hud: Node

func setup(hud: Node) -> void:
	_hud = hud

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_save_slots.resize(NUM_SLOTS)
	for i in NUM_SLOTS:
		_save_slots[i] = {}

func _process(_delta: float) -> void:
	if not is_active:
		return
	var state = Globals.CURRENT_GAME_STATE
	if state == Globals.GAME_STATE.IN_GAME:
		_was_in_game = true
	elif state == Globals.GAME_STATE.MAIN_MENU and _was_in_game:
		is_active = false
		_was_in_game = false
		for i in NUM_SLOTS:
			_save_slots[i] = {}
		print("Lifters: Practice mode deactivated (returned to menu).")

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or Globals.CURRENT_GAME_STATE != Globals.GAME_STATE.IN_GAME:
		return
	if not (event is InputEventKey and event.pressed):
		return

	var shift = event.shift_pressed

	match event.keycode:
		# 1-4 = load from slot
		KEY_1: _save_state_load(0)
		KEY_2: _save_state_load(1)
		KEY_3: _save_state_load(2)
		KEY_4: _save_state_load(3)
		# F1-F4 = save to slot
		KEY_F1: _save_state_capture(0)
		KEY_F2: _save_state_capture(1)
		KEY_F3: _save_state_capture(2)
		KEY_F4: _save_state_capture(3)
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

func _save_state_capture(slot: int) -> void:
	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if not player:
		return

	# Camera state
	var cam_pivot = player.get_node_or_null("CameraFollowPosition/CameraPivot")
	var cam_spring_length := 6.0
	var cam_rot := Vector3.ZERO
	if cam_pivot:
		cam_rot = cam_pivot.rotation
		var spring = cam_pivot.get_node_or_null("CameraSpringArm")
		if spring:
			cam_spring_length = spring.spring_length

	# Ice platform state — save position, scale, and alive_time
	var ice_plat_data := {}
	if is_instance_valid(player.current_ice_platform):
		var geom = player.current_ice_platform.find_child("Geometry")
		if geom:
			ice_plat_data = {
				"position": player.current_ice_platform.global_position,
				"alive_time": geom.alive_time,
				"scale": geom.scale,
				"death_pending": geom.death_pending,
			}

	var slot_name := str(slot + 1)
	_save_slots[slot] = {
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
		# Player state machine
		"player_state": player.state,
		"player_prev_state": player.prev_state,
		"time_spent_in_state": player._time_spent_in_state,
		"coyote_time_counter": player.coyote_time_counter,
		"jump_extend_continous_disabled": player.jump_extend_continous_disabled,
		# Camera
		"cam_rotation": cam_rot,
		"cam_spring_length": cam_spring_length,
		# Ice platform
		"ice_platform_credits": player.ice_platform_credits,
		"ice_platform_data": ice_plat_data,
	}
	if _hud:
		_hud.show_feedback("SLOT %s SAVED" % slot_name)
	print("Lifters: Slot %s saved at %s" % [slot_name, str(player.global_position)])

func _save_state_load(slot: int) -> void:
	var slot_name := str(slot + 1)
	var _save_state: Dictionary = _save_slots[slot]
	if _save_state.is_empty():
		if _hud:
			_hud.show_feedback("SLOT %s EMPTY" % slot_name)
		print("Lifters: Slot %s is empty." % slot_name)
		return

	var player = Globals.LEVEL_NODE.get_node_or_null("Player")
	if not player:
		return

	# Destroy any existing ice platform before restoring state
	if is_instance_valid(player.current_ice_platform):
		player.current_ice_platform.queue_free()
		player.current_ice_platform = null

	# Teleport player and update floor detection before restoring state.
	# is_on_floor() is stale until move_and_slide() runs, so we do a zero-velocity
	# slide to refresh it — otherwise airborne states instantly transition to ground.
	player.global_position = _save_state["position"]
	player.velocity = Vector3.ZERO
	player.move_and_slide()
	player.global_position = _save_state["position"]
	player.reset_physics_interpolation()

	# Now set state — is_on_floor() reflects the saved position
	player.set_state(_save_state["player_state"])
	player.prev_state = _save_state["player_prev_state"]
	player._time_spent_in_state = _save_state["time_spent_in_state"]
	player.coyote_time_counter = _save_state["coyote_time_counter"]
	player.jump_extend_continous_disabled = _save_state["jump_extend_continous_disabled"]

	# Restore velocity AFTER set_state so enter-state callbacks don't overwrite it
	player.velocity = _save_state["velocity"]

	# Restore camera rotation and zoom
	var cam_pivot = player.get_node_or_null("CameraFollowPosition/CameraPivot")
	if cam_pivot:
		cam_pivot.rotation = _save_state["cam_rotation"]
		cam_pivot.reset_physics_interpolation()
		SaveFileManager.LEVEL_SAVE_CONTENT["cam_rotation"] = _save_state["cam_rotation"]
		var spring = cam_pivot.get_node_or_null("CameraSpringArm")
		if spring:
			spring.spring_length = _save_state["cam_spring_length"]

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

	# Restore ice platform credits and recreate platform if one was active
	player.ice_platform_credits = _save_state["ice_platform_credits"]
	var ice_data: Dictionary = _save_state["ice_platform_data"]
	if not ice_data.is_empty():
		var new_plat = player.ice_platforms.pick_random().instantiate()
		Globals.LEVEL_NODE.add_child(new_plat)
		new_plat.global_position = ice_data["position"]
		var geom = new_plat.find_child("Geometry")
		if geom:
			geom.alive_time = ice_data["alive_time"]
			geom.scale = ice_data["scale"]
			geom.death_pending = ice_data["death_pending"]
		player.current_ice_platform = new_plat

	# Restore abilities and energy
	_recalc_abilities()
	player.energy = _save_state["energy"]

	if _hud:
		_hud.show_feedback("SLOT %s LOADED" % slot_name)
	print("Lifters: Slot %s loaded." % slot_name)

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
