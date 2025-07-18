# Modern Patrol State - Uses NavigationAgent3D for pathfinding
extends State
class_name ModernPatrolState

var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var patrol_wait_time: float = 0.0
var max_patrol_wait: float = 2.0  # Reduced wait time for more aggressive movement
var patrol_radius: float = 150.0  # Increased from 50 to 150 for map-wide coverage
var patrol_generation_timer: float = 0.0
var patrol_generation_interval: float = 20.0  # More frequent route updates
var aggressive_hunting: bool = true  # New flag for aggressive behavior
var last_known_enemy_areas: Array[Vector3] = []  # Areas where enemies were last seen

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	# Set relaxed patrol behavior
	agent.set_sprinting(false)
	agent.set_crouching(false)
	
	# Generate patrol points if we don't have any
	if patrol_points.is_empty():
		_generate_patrol_points(agent)
	
	# Set initial patrol target
	if not patrol_points.is_empty():
		agent.set_movement_target(patrol_points[current_patrol_index])
	else:
		# If no patrol points, just stay in place
		agent.set_movement_target(agent.global_position)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	patrol_generation_timer += delta
	
	# Check for enemies
	if agent.vision_system and not agent.vision_system.visible_entities.is_empty():
		for entity in agent.vision_system.visible_entities:
			var enemy = entity as FullyIntegratedFPSAgent
			if enemy and enemy.team_id != agent.team_id:
				agent.current_target = enemy
				agent.target_acquired.emit(enemy)
				agent.state_machine.change_state_by_name("combat")
				return
	
	# Handle patrol movement
	if agent.is_navigation_finished:
		patrol_wait_time += delta
		
		if patrol_wait_time >= max_patrol_wait:
			patrol_wait_time = 0.0
			_move_to_next_patrol_point(agent)
	
	# Regenerate patrol points occasionally for dynamic behavior
	if patrol_generation_timer > patrol_generation_interval:
		patrol_generation_timer = 0.0
		_generate_patrol_points(agent)

func _generate_patrol_points(agent: FullyIntegratedFPSAgent):
	patrol_points.clear()
	
	var nav_map = agent.navigation_agent.get_navigation_map()
	var center = agent.global_position
	
	# Create aggressive, map-wide patrol routes
	if aggressive_hunting:
		_generate_hunting_patrol_route(agent, nav_map)
	else:
		_generate_defensive_patrol_route(agent, nav_map, center)
	
	# Always include areas where enemies were last seen
	_add_priority_areas(agent, nav_map)
	
	# Ensure we have at least one patrol point
	if patrol_points.is_empty():
		patrol_points.append(agent.global_position)
	
	# Reset patrol index
	current_patrol_index = 0

func _generate_hunting_patrol_route(agent: FullyIntegratedFPSAgent, nav_map: RID):
	# Generate strategic patrol points across the entire map
	var map_center = Vector3.ZERO
	var strategic_areas = _get_strategic_areas(agent)
	
	# Add strategic positions
	for area in strategic_areas:
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, area)
		if closest_point.distance_to(area) < 15.0:
			patrol_points.append(closest_point)
	
	# Add enemy territory exploration points
	var enemy_spawn_areas = _get_enemy_spawn_areas(agent)
	for spawn_area in enemy_spawn_areas:
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, spawn_area)
		if closest_point.distance_to(spawn_area) < 15.0:
			patrol_points.append(closest_point)
	
	# Add random exploration points for unpredictability
	for i in range(3):
		var random_point = Vector3(
			randf_range(-200, 200),
			0,
			randf_range(-200, 200)
		)
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, random_point)
		if closest_point.distance_to(random_point) < 20.0:
			patrol_points.append(closest_point)

func _generate_defensive_patrol_route(agent: FullyIntegratedFPSAgent, nav_map: RID, center: Vector3):
	# Fallback to expanded local patrol if not hunting
	var point_count = 6 + randi() % 4  # 6-9 points
	
	for i in range(point_count):
		var angle = (i / float(point_count)) * TAU + randf_range(-0.4, 0.4)
		var distance = randf_range(patrol_radius * 0.3, patrol_radius)
		var patrol_point = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, patrol_point)
		if closest_point.distance_to(patrol_point) < 10.0:
			patrol_points.append(closest_point)

func _get_strategic_areas(agent: FullyIntegratedFPSAgent) -> Array[Vector3]:
	var strategic_areas: Array[Vector3] = []
	
	# Map center - always strategic
	strategic_areas.append(Vector3.ZERO)
	
	# High ground positions (if available)
	strategic_areas.append(Vector3(0, 10, 0))
	strategic_areas.append(Vector3(50, 5, 50))
	strategic_areas.append(Vector3(-50, 5, -50))
	
	# Chokepoints and corridors
	strategic_areas.append(Vector3(0, 0, 100))
	strategic_areas.append(Vector3(0, 0, -100))
	strategic_areas.append(Vector3(100, 0, 0))
	strategic_areas.append(Vector3(-100, 0, 0))
	
	return strategic_areas

func _get_enemy_spawn_areas(agent: FullyIntegratedFPSAgent) -> Array[Vector3]:
	var enemy_areas: Array[Vector3] = []
	
	# Approximate enemy spawn locations based on team
	if agent.team_id == 1:
		# Team 1 should hunt toward Team 2 spawn area
		enemy_areas.append(Vector3(125, 0, -125))
		enemy_areas.append(Vector3(110, 0, -110))
		enemy_areas.append(Vector3(100, 0, -100))
	else:
		# Team 2 should hunt toward Team 1 spawn area
		enemy_areas.append(Vector3(-125, 0, 125))
		enemy_areas.append(Vector3(-110, 0, 110))
		enemy_areas.append(Vector3(-100, 0, 100))
	
	return enemy_areas

func _add_priority_areas(agent: FullyIntegratedFPSAgent, nav_map: RID):
	# Add areas where enemies were last seen
	for area in last_known_enemy_areas:
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, area)
		if closest_point.distance_to(area) < 15.0:
			patrol_points.append(closest_point)
	
	# Add areas where we heard gunshots
	if agent.hearing_system:
		# This would be populated by the hearing system
		pass

func _move_to_next_patrol_point(agent: FullyIntegratedFPSAgent):
	if patrol_points.is_empty():
		return
	
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	agent.set_movement_target(patrol_points[current_patrol_index])
	
	# Vary patrol behavior slightly
	max_patrol_wait = randf_range(2.0, 5.0)

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		patrol_wait_time = 0.0
