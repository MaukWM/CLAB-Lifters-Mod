# Lifters

A [GML](https://github.com/GodotModding/godot-mod-loader) mod introducing QoL stuff for speedrunners for [Cirno! Lifts a Boulder](https://store.steampowered.com/app/4173110/Cirno_Lifts_a_Boulder/).

> Work in progress — features coming soon.

## Installation

### Prerequisites

1. **Cirno! Lifts a Boulder** installed via Steam (Windows)
2. **Godot Mod Loader (GML)** installed for the game

### Install GML (one-time)

1. Download the latest GML release from the [Godot Mod Loader releases](https://github.com/GodotModding/godot-mod-loader/releases)
2. Extract the GML files into the game directory alongside the game executable
3. Add the Steam launch option: `--script addons/mod_loader/mod_loader_setup.gd`
4. Launch the game — the window title should show "(Modded)"

### Install Lifters

1. Download `MaukWM-Lifters-X.Y.Z.zip` from the [latest release](https://github.com/MaukWM/CLAB-Lifters-Mod/releases/latest)
2. Extract the zip into the game directory so that `mods-unpacked/MaukWM-Lifters/` exists next to the game executable
3. Launch the game

## Settings

Settings are stored in `user://lifters/settings.json`. Location on disk:

| OS | Path |
|----|------|
| Windows | `%APPDATA%\Godot\app_userdata\Cirno! Lifts a Boulder\lifters\settings.json` |

The `version` field in the settings file is a schema version (not the mod version). It increments only when the settings structure changes, to support automatic migration of existing configs.

## License

MIT
