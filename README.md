# Lifters

Speedrun QoL mod for [Cirno! Lifts a Boulder](https://store.steampowered.com/app/4173110/Cirno_Lifts_a_Boulder/). Uses Godot 4.6's native `override.cfg` + `autoload_prepend`, GML is not needed.

> Work in progress — features coming soon.

## Installation

### Prerequisites

1. **Cirno! Lifts a Boulder** installed via Steam (Windows)

### Install Lifters

1. Download `MaukWM-Lifters-X.Y.Z.zip` from the [latest release](https://github.com/MaukWM/CLAB-Lifters-Mod/releases/latest)
2. Extract the zip contents into your game directory (right-click game in Steam → Manage → Browse Local Files)
3. You should see `override.cfg` and `lifters/` next to `Cirno Lifts a Boulder.exe`
4. Launch the game

### Uninstall

Delete `override.cfg` and the `lifters/` folder from the game directory.

## Settings

Settings are stored in `user://lifters/settings.json`. Location on disk:

| OS | Path |
|----|------|
| Windows | `%APPDATA%\Godot\app_userdata\Cirno! Lifts a Boulder\lifters\settings.json` |

The `version` field in the settings file is a schema version (not the mod version). It increments only when the settings structure changes, to support automatic migration of existing configs.

## License

MIT
