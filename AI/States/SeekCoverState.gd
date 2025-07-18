# Seek Cover State
extends State
class_name SeekCoverState

var cover_position: Vector3
var time_in_cover: float = 0.0
var max_cover_time: float = 5.0

func enter(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if not agent: return
	
	# Find the best available cover position
	cover_position = agent.find_cover()
	
	if cover_position == Vector3.ZERO:
		# No cover found, revert to the previous state (likely combat)
		agent.state_machine.revert_to_previous_state()
		return
	
	time_in_cover = 0.0
	agent.steering_manager.behaviors.clear()
	agent.steering_manager.add(ArriveBehavior.new(cover_position))

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FPSAgent
	if not agent: return
	
	# If we've reached cover
	if agent.global_position.distance_squared_to(cover_position) < 2.25: # 1.5m radius
		agent.velocity = Vector3.ZERO # Stop moving
		time_in_cover += delta
		
		# Peek and shoot occasionally (can be made more complex)
		if agent.current_target and is_instance_valid(agent.current_target):
			if fmod(time_in_cover, 2.0) < delta: # Every 2 seconds
				agent.weapon_system.fire_at(agent.current_target.global_position)
		
		# Leave cover after a while, or if health is high
		if time_in_cover > max_cover_time or agent.health > agent.max_health * 0.8:
			agent.state_machine.change_state_by_name("combat")
	
	# If the enemy gets too close, abandon cover and fight
	if agent.current_target and agent.global_position.distance_to(agent.current_target.global_position) < 5.0:
		agent.state_machine.change_state_by_name("combat")
