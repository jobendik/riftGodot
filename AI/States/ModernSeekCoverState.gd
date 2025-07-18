# Modern Seek Cover State - Updated for NavigationAgent3D
extends State
class_name ModernSeekCoverState

var cover_position: Vector3
var time_in_cover: float = 0.0
var max_cover_time: float = 5.0
var cover_search_attempts: int = 0
var max_cover_attempts: int = 3

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	time_in_cover = 0.0
	cover_search_attempts = 0
	
	_find_and_move_to_cover(agent)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	# If we reached cover position
	if agent.is_navigation_finished:
		time_in_cover += delta
		
		# Peek and shoot occasionally
		if agent.current_target and is_instance_valid(agent.current_target):
			if fmod(time_in_cover, 2.0) < delta:  # Every 2 seconds
				if agent.weapon_system and agent.weapon_system.can_fire():
					agent.weapon_system.fire_at(agent.current_target.global_position)
		
		# Leave cover after a while or if health is better
		if time_in_cover > max_cover_time or agent.health > agent.max_health * 0.8:
			agent.state_machine.change_state_by_name("combat")
			return
	
	# If enemy gets too close, abandon cover
	if agent.current_target and agent.global_position.distance_to(agent.current_target.global_position) < 8.0:
		agent.state_machine.change_state_by_name("combat")
		return
	
	# If we can't find cover, try again or give up
	if cover_position == Vector3.ZERO and agent.is_navigation_finished:
		cover_search_attempts += 1
		if cover_search_attempts >= max_cover_attempts:
			# Give up on finding cover, go back to combat
			agent.state_machine.change_state_by_name("combat")
		else:
			_find_and_move_to_cover(agent)

func _find_and_move_to_cover(agent: FullyIntegratedFPSAgent):
	cover_position = agent.find_cover()
	
	if cover_position == Vector3.ZERO:
		# Try moving to a random nearby position as fallback
		var fallback_pos = agent.global_position + Vector3(
			randf_range(-15, 15),
			0,
			randf_range(-15, 15)
		)
		
		var nav_map = agent.navigation_agent.get_navigation_map()
		cover_position = NavigationServer3D.map_get_closest_point(nav_map, fallback_pos)
	
	if cover_position != Vector3.ZERO:
		agent.set_movement_target(cover_position)
		agent.set_crouching(true)
		
		# Reduce speed when seeking cover (more cautious)
		agent.navigation_agent.max_speed = agent.movement_speed * 0.7

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.set_crouching(false)
		# Restore normal movement speed
		agent.navigation_agent.max_speed = agent.movement_speed
