class_name Interactable
extends Node3D

signal prompt_changed(text: String)

func get_prompt(player: PlayerController = null) -> String:
	return ""

func interact(player: PlayerController) -> void:
	pass
