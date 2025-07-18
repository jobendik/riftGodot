# Global Sound Manager - Manages all sound events in the game
extends Node
class_name SoundManager

static var instance: SoundManager
var listeners: Array[HearingSystem] = []

func _enter_tree():
	# Singleton pattern setup
	if not instance:
		instance = self

func _exit_tree():
	if instance == self:
		instance = null

func register_listener(listener: HearingSystem) -> void:
	if listener not in listeners:
		listeners.append(listener)

func unregister_listener(listener: HearingSystem) -> void:
	listeners.erase(listener)

func emit_sound(position: Vector3, loudness: float, type: String, source: GameEntity = null) -> void:
	var event = HearingSystem.SoundEvent.new(position, loudness, type, source)
	
	# Create a copy of the listeners array to iterate over, in case it's modified during processing
	for listener in listeners.duplicate():
		if is_instance_valid(listener):
			listener.process_sound(event)
