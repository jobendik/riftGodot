# Modern Heal State - Updated for NavigationAgent3D
extends State
class_name ModernHealState

var heal_target_pos: Vector3
var healing_started: bool = false
var healing_timer: float = 0.0
var healing_duration: float = 5.0
var search_attempts: int = 0
var max_search_attempts: int = 3

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	healing_started = false
	healing_timer = 0.0
	search_attempts = 0
	
	# Find health pack or safe healing location
	heal_target_pos = _find_health_location(agent)
	
	if heal_target_pos != Vector3.ZERO:
		agent.set_movement_target(heal_target_pos)
		agent.set_crouching(true)  # Crouch for safety while healing
	else:
		# If no specific health location found, find cover to heal
		heal_target_pos = agent.find_cover()
		if heal_target_pos != Vector3.ZERO:
			agent.set_movement_target(heal_target_pos)
			agent.set_crouching(true)
		else:
			# No safe place found, abort healing
			agent.state_machine.change_state_by_name("seek_cover")

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	# If health is full, we're done
	if agent.health >= agent.max_health * 0.95:
		agent.state_machine.change_state_by_name("patrol")
		return
	
	# If an enemy is spotted, abort healing and fight
	if agent.vision_system and not agent.vision_system.visible_entities.is_empty():
		for entity in agent.vision_system.visible_entities:
			var enemy = entity as FullyIntegratedFPSAgent
			if enemy and enemy.team_id != agent.team_id:
				agent.current_target = enemy
				agent.state_machine.change_state_by_name("combat")
				return
	
	# Check if we reached the healing location
	if not healing_started and agent.is_navigation_finished:
		var distance = agent.global_position.distance_to(heal_target_pos)
		if distance < 3.0:
			healing_started = true
			healing_timer = 0.0
			print(agent.name + " started healing at location")
	
	# Perform healing if we're at the location
	if healing_started:
		healing_timer += delta
		
		# Heal gradually over time
		var heal_rate = 20.0  # Health per second
		agent.health_system.heal(heal_rate * delta)
		
		# Check if we've been healing long enough or are interrupted
		if healing_timer >= healing_duration:
			agent.state_machine.change_state_by_name("patrol")
			return
		
		# If we're under attack, stop healing
		if agent.current_target or agent.stress_level > 0.5:
			agent.state_machine.change_state_by_name("combat")
			return
	
	# If we haven't reached the healing location in reasonable time, try another
	if not healing_started and agent.is_navigation_finished:
		search_attempts += 1
		if search_attempts >= max_search_attempts:
			# Give up on finding perfect healing spot, heal in place
			healing_started = true
			healing_timer = 0.0
		else:
			# Try to find another healing location
			heal_target_pos = _find_health_location(agent)
			if heal_target_pos != Vector3.ZERO:
				agent.set_movement_target(heal_target_pos)

func _find_health_location(agent: FullyIntegratedFPSAgent) -> Vector3:
	# Look for health pack pickups in the scene
	var health_packs = get_tree().get_nodes_in_group("health_pack")
	if not health_packs.is_empty():
		var closest_pack = null
		var closest_distance = INF
		
		for pack in health_packs:
			if pack is Node3D:
				var distance = agent.global_position.distance_to(pack.global_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_pack = pack
		
		if closest_pack:
			return closest_pack.global_position
	
	# Look for designated healing areas
	var healing_areas = get_tree().get_nodes_in_group("healing_area")
	if not healing_areas.is_empty():
		var closest_area = healing_areas.pick_random() as Node3D
		if closest_area:
			return closest_area.global_position
	
	# Fallback: find a safe, secluded spot
	return _find_safe_healing_spot(agent)

func _find_safe_healing_spot(agent: FullyIntegratedFPSAgent) -> Vector3:
	# Find a quiet corner or safe area to heal
	var current_pos = agent.global_position
	var nav_map = agent.navigation_agent.get_navigation_map()
	
	# Try several random positions around the agent
	for i in range(8):
		var angle = (i / 8.0) * TAU
		var test_pos = current_pos + Vector3(cos(angle), 0, sin(angle)) * 20.0
		
		# Validate position on navmesh
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, test_pos)
		if closest_point.distance_to(test_pos) < 5.0:
			# Check if this position has some cover
			if _position_has_cover(agent, closest_point):
				return closest_point
	
	# If no good spot found, just use current position
	return current_pos

func _position_has_cover(agent: FullyIntegratedFPSAgent, pos: Vector3) -> bool:
	# Check if position has some form of cover by testing multiple directions
	var space_state = agent.get_world_3d().direct_space_state
	var cover_found = false
	
	for i in range(8):
		var angle = (i / 8.0) * TAU
		var direction = Vector3(cos(angle), 0, sin(angle))
		var test_pos = pos + direction * 10.0
		
		var query = PhysicsRayQueryParameters3D.create(
			pos + Vector3.UP,
			test_pos + Vector3.UP
		)
		query.collision_mask = 1  # World geometry
		
		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			cover_found = true
			break
	
	return cover_found

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.set_crouching(false)
		if healing_started:
			print(agent.name + " finished healing session")
