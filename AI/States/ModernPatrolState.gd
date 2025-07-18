# Modern Patrol State - Uses NavigationAgent3D for pathfinding
extends State
class_name ModernPatrolState

var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var patrol_wait_time: float = 0.0
var max_patrol_wait: float = 3.0
var patrol_radius: float = 50.0
var patrol_generation_timer: float = 0.0
var patrol_generation_interval: float = 30.0

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
	
	# Generate points in a radius around the agent's current position
	var center = agent.global_position
	var point_count = 4 + randi() % 4  # 4-7 points
	var nav_map = agent.navigation_agent.get_navigation_map()
	
	for i in range(point_count):
		var angle = (i / float(point_count)) * TAU + randf_range(-0.4, 0.4)
		var distance = randf_range(patrol_radius * 0.5, patrol_radius)
		var patrol_point = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		# Try to find a valid navigation point
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, patrol_point)
		
		if closest_point.distance_to(patrol_point) < 10.0:  # Point is reasonably close to navmesh
			patrol_points.append(closest_point)
	
	# Ensure we have at least one patrol point
	if patrol_points.is_empty():
		patrol_points.append(agent.global_position)
	
	# Reset patrol index
	current_patrol_index = 0

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
