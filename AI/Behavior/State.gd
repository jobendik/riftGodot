# Base State class
extends RefCounted
class_name State

func enter(owner: GameEntity) -> void:
	pass

func execute(owner: GameEntity, delta: float) -> void:
	pass

func exit(owner: GameEntity) -> void:
	pass

func on_message(owner: GameEntity, msg: Message) -> bool:
	return false
