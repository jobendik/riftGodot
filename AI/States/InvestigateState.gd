# Investigation State - For checking out suspicious sounds/sights
extends State
class_name InvestigateState

var investigation_target: Vector3
var investigation_time: float = 0.0
var max_investigation_time: float = 10.0
var search_points: Array[Vector3] = []
var current_search_index: int = 0
var investigation_radius: float = 15.0

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	investigation_target = agent.movement_target
	investigation_time = 0.0
	current_search_index = 0
	
	# Generate search points around the investigation area
	_generate_search_points(agent)
	
	# Set cautious movement
	agent.set_crouching(true)
	agent.navigation_agent.max_speed = agent.movement_speed * 0.6  # Move slower when investigating
	
	# Start investigating the target position
	if search_points.size() > 0:
		agent.set_movement_target(search_points[0])
	else:
		agent.set_movement_target(investigation_target)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	investigation_time += delta
	
	# Check for enemies during investigation
	if agent.vision_system and not agent.vision_system.visible_entities.is_empty():
		for entity in agent.vision_system.visible_entities:
			var enemy = entity as FullyIntegratedFPSAgent
			if enemy and enemy.team_id != agent.team_id:
				agent.current_target = enemy
				agent.target_acquired.emit(enemy)
				agent.state_machine.change_state_by_name("combat")
				return
	
	# Handle search pattern
	if agent.is_navigation_finished:
		if current_search_index < search_points.size():
			agent.set_movement_target(search_points[current_search_index])
			current_search_index += 1
		else:
			# Finished searching all points
			_complete_investigation(agent)
			return
	
	# Timeout investigation
	if investigation_time > max_investigation_time:
		_complete_investigation(agent)

func _generate_search_points(agent: FullyIntegratedFPSAgent):
	search_points.clear()
	
	var point_count = 6
	var nav_map = agent.navigation_agent.get_navigation_map()
	
	# Create search points in a pattern around the investigation target
	for i in range(point_count):
		var angle = (i / float(point_count)) * TAU
		var distance = randf_range(investigation_radius * 0.3, investigation_radius)
		var search_point = investigation_target + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		# Validate point on navmesh
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, search_point)
		
		if closest_point.distance_to(search_point) < 5.0:
			search_points.append(closest_point)
	
	# Add the investigation target itself as the final search point
	var target_on_navmesh = NavigationServer3D.map_get_closest_point(nav_map, investigation_target)
	if target_on_navmesh.distance_to(investigation_target) < 5.0:
		search_points.append(target_on_navmesh)
	
	# Shuffle search points for unpredictability
	search_points.shuffle()

func _complete_investigation(agent: FullyIntegratedFPSAgent):
	# Investigation complete, return to normal behavior
	print(agent.name + " completed investigation of area")
	
	# Check if we should report back to team
	if agent.team_id > 0:
		var report_msg = TeamCommunication.TeamMessage.new(
			"area_investigated",
			{
				"investigator": agent,
				"location": investigation_target,
				"result": "no_threats_found"
			},
			agent,
			TeamCommunication.MessagePriority.LOW
		)
		TeamCommunication.broadcast(agent.team_id, report_msg)
	
	# Return to patrol
	agent.state_machine.change_state_by_name("patrol")

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.set_crouching(false)
		# Restore normal movement speed
		agent.navigation_agent.max_speed = agent.movement_speed
