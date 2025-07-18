# Hearing System - Sound perception for AI agents
extends Node3D
class_name HearingSystem

@export var hearing_range: float = 20.0
@export var hearing_sensitivity: float = 1.0
var owner_entity: GameEntity
var heard_sounds: Array[SoundEvent] = []

class SoundEvent extends RefCounted:
	var position: Vector3
	var loudness: float
	var type: String # "footstep", "gunshot", "reload", "voice", etc.
	var source: GameEntity
	var timestamp: float
	
	func _init(pos: Vector3, loud: float, sound_type: String, src: GameEntity = null):
		position = pos
		loudness = loud
		type = sound_type
		source = src
		timestamp = Time.get_ticks_msec() / 1000.0

signal sound_heard(event: SoundEvent)

func _ready():
	# Register with the global sound manager if it exists
	if SoundManager.instance:
		SoundManager.instance.register_listener(self)

func can_hear(sound_position: Vector3, loudness: float) -> bool:
	var distance = global_position.distance_to(sound_position)
	var effective_range = hearing_range * hearing_sensitivity * loudness
	
	if distance > effective_range:
		return false
	
	# Check for obstacles that might muffle the sound
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		sound_position + Vector3.UP
	)
	query.collision_mask = 1 # Assumes world geometry is on layer 1
	
	var result = space_state.intersect_ray(query)
	if result:
		# Sound is muffled by obstacles, reduce effective range
		effective_range *= 0.5
		return distance <= effective_range
	
	return true

func process_sound(event: SoundEvent) -> void:
	if can_hear(event.position, event.loudness):
		heard_sounds.append(event)
		sound_heard.emit(event)
		
		# Directly alert the AI owner if it has the appropriate method
		if owner_entity and owner_entity.has_method("on_sound_heard"):
			owner_entity.on_sound_heard(event)
		
		# Clean up old sounds to prevent the array from growing indefinitely
		_clean_old_sounds()

func _clean_old_sounds():
	var current_time = Time.get_ticks_msec() / 1000.0
	heard_sounds = heard_sounds.filter(func(event): return current_time - event.timestamp < 5.0)

func _on_tree_exiting():
	# Unregister from the sound manager when this node is removed
	if SoundManager.instance:
		SoundManager.instance.unregister_listener(self)
