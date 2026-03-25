# Lifters — Autoload entry point (override.cfg + autoload_prepend)
extends Node

func _init() -> void:
	print("Lifters: _init() called — mod is loading!")

func _ready() -> void:
	print("Lifters: _ready() called — mod is in the scene tree!")
	print("Lifters: Game state = ", Globals.CURRENT_GAME_STATE)
