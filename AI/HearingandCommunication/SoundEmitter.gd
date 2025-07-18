# Sound Emitter Component - Attach to entities that make sounds
extends Node3D
class_name SoundEmitter

var owner_entity: GameEntity
@export var footstep_loudness: float = 0.3
@export var footstep_interval: float = 0.5
var time_since_last_footstep: float = 0.0

func _ready():
	# The emitter's owner is its parent node
	owner_entity = get_parent() as GameEntity

func _process(delta: float):
	if not is_instance_valid(owner_entity): return
	
	# Emit footstep sounds based on velocity
	var vehicle = owner_entity as Vehicle
	if vehicle and vehicle.velocity.length() > 0.1:
		time_since_last_footstep += delta
		if time_since_last_footstep >= footstep_interval:
			var loudness = footstep_loudness * (vehicle.velocity.length() / vehicle.max_speed)
			emit_footstep(loudness)
			time_since_last_footstep = 0.0

func emit_footstep(loudness: float):
	if SoundManager.instance:
		SoundManager.instance.emit_sound(global_position, loudness, "footstep", owner_entity)

func emit_gunshot(weapon_name: String):
	if not SoundManager.instance: return
	var loudness = 1.0
	match weapon_name.to_lower():
		"shotgun": loudness = 1.2
		"rifle": loudness = 1.0
		"sniper": loudness = 1.5
		"pistol": loudness = 0.8
	SoundManager.instance.emit_sound(global_position, loudness, "gunshot", owner_entity)

func emit_reload():
	if SoundManager.instance:
		SoundManager.instance.emit_sound(global_position, 0.4, "reload", owner_entity)

func emit_voice(message: String):
	if SoundManager.instance:
		# The message content could be used for more advanced systems
		SoundManager.instance.emit_sound(global_position, 0.6, "voice", owner_entity)
