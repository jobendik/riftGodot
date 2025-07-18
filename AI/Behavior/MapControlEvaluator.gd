extends GoalEvaluator
class_name MapControlEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.0
	
	# Higher priority if we're not in combat
	if not agent.current_target:
		desirability = 0.6
	else:
		desirability = 0.1  # Lower priority during combat
	
	# Increase if we're far from strategic positions
	var distance_to_center = agent.global_position.distance_to(Vector3.ZERO)
	if distance_to_center > 100.0:
		desirability += 0.3
	
	# Increase if we haven't seen enemies in a while
	if agent.time_since_last_enemy_seen > 15.0:
		desirability += 0.2
	
	# Increase if we're in a bad position (exposed, no cover nearby)
	if _is_in_exposed_position(agent):
		desirability += 0.25
	
	# Increase based on team coordination needs
	if _should_coordinate_with_team(agent):
		desirability += 0.15
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	# Find the best strategic position to move to
	var target_position = _find_best_strategic_position(agent)
	
	if target_position != Vector3.ZERO:
		agent.set_movement_target(target_position)
		agent.state_machine.change_state_by_name("patrol")
	else:
		# Fallback to normal patrol
		agent.state_machine.change_state_by_name("patrol")

func _find_best_strategic_position(agent: FullyIntegratedFPSAgent) -> Vector3:
	var strategic_positions = _get_strategic_positions(agent)
	var best_position = Vector3.ZERO
	var best_score = -INF
	
	for position in strategic_positions:
		var score = _evaluate_strategic_position(agent, position)
		if score > best_score:
			best_score = score
			best_position = position
	
	return best_position

func _get_strategic_positions(agent: FullyIntegratedFPSAgent) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	
	# Map center - always strategic
	positions.append(Vector3.ZERO)
	
	# High ground positions
	positions.append(Vector3(0, 10, 0))
	positions.append(Vector3(25, 5, 25))
	positions.append(Vector3(-25, 5, -25))
	positions.append(Vector3(25, 5, -25))
	positions.append(Vector3(-25, 5, 25))
	
	# Chokepoint control positions
	positions.append(Vector3(0, 0, 50))
	positions.append(Vector3(0, 0, -50))
	positions.append(Vector3(50, 0, 0))
	positions.append(Vector3(-50, 0, 0))
	
	# Forward positions toward enemy territory
	if agent.team_id == 1:
		# Team 1 pushes toward Team 2 area
		positions.append(Vector3(75, 0, -75))
		positions.append(Vector3(50, 0, -100))
		positions.append(Vector3(100, 0, -50))
	else:
		# Team 2 pushes toward Team 1 area
		positions.append(Vector3(-75, 0, 75))
		positions.append(Vector3(-50, 0, 100))
		positions.append(Vector3(-100, 0, 50))
	
	# Flanking positions
	positions.append(Vector3(75, 0, 0))
	positions.append(Vector3(-75, 0, 0))
	positions.append(Vector3(0, 0, 75))
	positions.append(Vector3(0, 0, -75))
	
	return positions

func _evaluate_strategic_position(agent: FullyIntegratedFPSAgent, position: Vector3) -> float:
	var score = 0.0
	
	# Distance factor - closer positions are generally better
	var distance = agent.global_position.distance_to(position)
	score -= distance * 0.01
	
	# Check if position is accessible
	if not _is_position_accessible(agent, position):
		return -INF
	
	# Height advantage
	if position.y > agent.global_position.y:
		score += 10.0
	
	# Distance to map center - central positions are valuable
	var distance_to_center = position.distance_to(Vector3.ZERO)
	score -= distance_to_center * 0.02
	
	# Proximity to enemy territory
	var enemy_spawn_distance = _get_distance_to_enemy_spawn(agent, position)
	if enemy_spawn_distance > 50.0 and enemy_spawn_distance < 150.0:
		score += 15.0  # Sweet spot for aggressive positioning
	
	# Cover availability
	if _has_cover_nearby(agent, position):
		score += 8.0
	
	# Avoid crowded areas (if teammates are nearby)
	var teammate_count = _count_nearby_teammates(agent, position)
	if teammate_count > 2:
		score -= 5.0 * teammate_count
	
	return score

func _is_position_accessible(agent: FullyIntegratedFPSAgent, position: Vector3) -> bool:
	var nav_map = agent.navigation_agent.get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(nav_map, position)
	return closest_point.distance_to(position) < 10.0

func _get_distance_to_enemy_spawn(agent: FullyIntegratedFPSAgent, position: Vector3) -> float:
	var enemy_spawn_center: Vector3
	
	if agent.team_id == 1:
		enemy_spawn_center = Vector3(125, 0, -125)
	else:
		enemy_spawn_center = Vector3(-125, 0, 125)
	
	return position.distance_to(enemy_spawn_center)

func _has_cover_nearby(agent: FullyIntegratedFPSAgent, position: Vector3) -> bool:
	# Simple cover check - look for obstacles around the position
	var space_state = agent.get_world_3d().direct_space_state
	var cover_found = false
	
	for angle in range(0, 360, 45):
		var check_pos = position + Vector3(cos(deg_to_rad(angle)), 0, sin(deg_to_rad(angle))) * 3.0
		var query = PhysicsRayQueryParameters3D.create(position + Vector3.UP, check_pos + Vector3.UP)
		query.collision_mask = 1
		
		var result = space_state.intersect_ray(query)
		if result:
			cover_found = true
			break
	
	return cover_found

func _count_nearby_teammates(agent: FullyIntegratedFPSAgent, position: Vector3) -> int:
	var count = 0
	var search_radius = 20.0
	
	if agent.entity_manager:
		var nearby_entities = agent.entity_manager.get_neighbors(agent, search_radius)
		for entity in nearby_entities:
			var other_agent = entity as FullyIntegratedFPSAgent
			if other_agent and other_agent.team_id == agent.team_id:
				if other_agent.global_position.distance_to(position) < search_radius:
					count += 1
	
	return count

func _is_in_exposed_position(agent: FullyIntegratedFPSAgent) -> bool:
	# Check if agent is in an exposed position (no cover nearby)
	return not _has_cover_nearby(agent, agent.global_position)

func _should_coordinate_with_team(agent: FullyIntegratedFPSAgent) -> bool:
	# Check if we should move to coordinate with teammates
	if not agent.entity_manager:
		return false
	
	var teammates = []
	var nearby_entities = agent.entity_manager.get_neighbors(agent, 50.0)
	
	for entity in nearby_entities:
		var other_agent = entity as FullyIntegratedFPSAgent
		if other_agent and other_agent.team_id == agent.team_id:
			teammates.append(other_agent)
	
	# If we have teammates nearby but they're spread out, we should coordinate
	return teammates.size() > 0 and teammates.size() < 2
