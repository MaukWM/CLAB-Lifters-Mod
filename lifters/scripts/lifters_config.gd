# Settings singleton. Load/save/defaults for user://lifters/settings.json.
# All other components read from this via get_setting() and react to setting_changed.
extends Node

signal setting_changed(key: String, value: Variant)

const SETTINGS_DIR = "user://lifters/"
const SETTINGS_PATH = "user://lifters/settings.json"
const CURRENT_VERSION = 1

var _data: Dictionary = {}

var DEFAULTS: Dictionary = {
	"version": CURRENT_VERSION,
	"skip_intro_story": true,
	"skip_endgame_story": false,
	"disable_save": false,
	"autosplit": {
		"enabled": true,
		"livesplit_host": "127.0.0.1",
		"livesplit_port": 16834,
		"emit_on_frog": false,
		"emit_on_power": true,
		"power_interval": 0.50,
		"emit_on_score": false,
		"score_interval": 100,
		"emit_on_boulder_lift": true,
	},
}

func _ready() -> void:
	_load()
	print("Lifters Config: Loaded settings (version ", _data.get("version", "?"), ")")

# Dot-notation access: get_setting("autosplit.emit_on_frog")
func get_setting(key: String) -> Variant:
	var parts = key.split(".")
	var current: Variant = _data
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			# Fall back to defaults
			current = DEFAULTS
			for p in parts:
				if current is Dictionary and current.has(p):
					current = current[p]
				else:
					return null
			return current
	return current

# Dot-notation write: set_setting("autosplit.emit_on_frog", true)
func set_setting(key: String, value: Variant) -> void:
	var parts = key.split(".")
	var current: Variant = _data
	for i in range(parts.size() - 1):
		if current is Dictionary and current.has(parts[i]):
			current = current[parts[i]]
		else:
			return
	if current is Dictionary:
		current[parts[-1]] = value
		setting_changed.emit(key, value)

func save() -> void:
	DirAccess.make_dir_recursive_absolute(SETTINGS_DIR)
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data, "\t"))
		file.close()
		print("Lifters Config: Settings saved.")

func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("Lifters Config: No settings file found, creating defaults.")
		_data = DEFAULTS.duplicate(true)
		save()
		return

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		_data = parsed
		_coerce_types(_data, DEFAULTS)
		_migrate()
	else:
		print("Lifters Config: Invalid settings file, resetting to defaults.")
		_data = DEFAULTS.duplicate(true)
		save()

# Merge missing keys from DEFAULTS when version is outdated
func _migrate() -> void:
	var file_version = _data.get("version", 0)
	if file_version < CURRENT_VERSION:
		print("Lifters Config: Migrating from version ", file_version, " to ", CURRENT_VERSION)
		_merge_defaults(_data, DEFAULTS)
		_data["version"] = CURRENT_VERSION
		save()

# JSON loses int vs float distinction — coerce types to match DEFAULTS
func _coerce_types(target: Dictionary, defaults: Dictionary) -> void:
	for key in target:
		if not defaults.has(key):
			continue
		if target[key] is Dictionary and defaults[key] is Dictionary:
			_coerce_types(target[key], defaults[key])
		elif defaults[key] is int and target[key] is float:
			target[key] = int(target[key])

func _merge_defaults(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults:
		if not target.has(key):
			target[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary else defaults[key]
		elif target[key] is Dictionary and defaults[key] is Dictionary:
			_merge_defaults(target[key], defaults[key])
