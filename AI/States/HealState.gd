# Heal State
extends State
class_name HealState

var heal_target_pos: Vector3

func enter(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if not agent: return
	
	# Find the nearest health pack or a safe spot
	heal_target_pos = _find_health_location(agent)
	
	if heal_target_pos != Vector3.ZERO:
		agent.steering_manager.behaviors.clear()
		agent.steering_manager.add(SeekBehavior.new(heal_target_pos))
	else:
		# If no health pack is found, just seek cover instead
		agent.state_machine.change_state_by_name("seek_cover")

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FPSAgent
	if not agent: return
	
	# If health is full, we're done
	if agent.health >= agent.max_health * 0.95:
		agent.state_machine.change_state_by_name("patrol")
		return
	
	# If an enemy is spotted, abort healing and fight
	if agent.vision_system and not agent.vision_system.visible_entities.is_empty():
		agent.state_machine.change_state_by_name("combat")
		return
		
	# If at the location, apply healing (assuming it's an item to be picked up)
	if agent.global_position.distance_squared_to(heal_target_pos) < 4.0:
		# This part depends on your game's item system.
		# For now, we'll just simulate finding it and healing.
		agent.health_system.heal(50) # Example heal amount
		# The state will change on the next frame when health is high enough
		
func _find_health_location(agent: FPSAgent) -> Vector3:
	# This requires knowledge of where health packs are in the world.
	# Placeholder logic. In a real game, you'd query an item manager.
	print("HealState: _find_health_location() needs to be implemented.")
	return Vector3.ZERO
