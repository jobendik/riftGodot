# Modern FPS Game Manager - Handles AI agents with proper navigation setup
extends Node3D
class_name ModernFPSGameManager

@export var agent_scene: PackedScene
@export var max_team_size: int = 8
@export var respawn_time: float = 5.0
@export var enable_debug_visualization: bool = true

# Navigation setup
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
var navigation_mesh: NavigationMesh

# Agent management
var entity_manager: EntityManager
var team_1_agents: Array[ModernFPSAgent] = []
var team_2_agents: Array[ModernFPSAgent] = []
var all_agents: Array[ModernFPSAgent] = []

# Spawn points - should be set up in the scene or generated
var team_1_spawn_points: Array[Vector3] = []
var team_2_spawn_points: Array[Vector3] = []

# Game state
var game_active: bool = false
var game_time: float = 0.0

signal agents_spawned
signal navigation_ready

func _ready():
	_initialize_navigation()
	_initialize_entity_manager()
	_setup_spawn_points()
	
	# Wait for navigation to be ready before spawning agents
	if navigation_region:
		# Wait one frame for navigation to initialize
		await get_tree().process_frame
		_wait_for_navigation_ready()

func _wait_for_navigation_ready():
	# Check if navigation map is ready
	var nav_map = navigation_region.get_navigation_map()
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().process_frame
	
	navigation_ready.emit()
	_spawn_initial_teams()

func _initialize_navigation():
	if not navigation_region:
		# Create navigation region if it doesn't exist
		navigation_region = NavigationRegion3D.new()
		navigation_region.name = "NavigationRegion3D"
		add_child(navigation_region)
	
	# Set up navigation mesh if not already configured
	if not navigation_region.navigation_mesh:
		navigation_mesh = NavigationMesh.new()
		
		# Configure navigation mesh for FPS gameplay
		navigation_mesh.cell_size = 0.25
		navigation_mesh.cell_height = 0.1
		navigation_mesh.agent_radius = 0.6
		navigation_mesh.agent_height = 1.8
		navigation_mesh.agent_max_climb = 1.5
		navigation_mesh.agent_max_slope = 45.0
		navigation_mesh.region_min_size = 2
		navigation_mesh.region_merge_size = 20
		navigation_mesh.edge_max_length = 10.0
		navigation_mesh.edge_max_error = 3.0
		navigation_mesh.vertices_per_polygon = 6
		navigation_mesh.detail_sample_distance = 6.0
		navigation_mesh.detail_sample_max_error = 1.0
		
		# Filter settings for multi-level environments
		navigation_mesh.filter_low_hanging_obstacles = true
		navigation_mesh.filter_ledge_spans = true
		navigation_mesh.filter_walkable_low_height_spans = true
		
		navigation_region.navigation_mesh = navigation_mesh
		
		print("Navigation mesh configured for FPS gameplay")

func _initialize_entity_manager():
	entity_manager = EntityManager.new()
	add_child(entity_manager)

func _setup_spawn_points():
	# Look for spawn point nodes in the scene
	var spawn_group_1 = get_tree().get_nodes_in_group("team_1_spawn")
	var spawn_group_2 = get_tree().get_nodes_in_group("team_2_spawn")
	
	for spawn_point in spawn_group_1:
		if spawn_point is Node3D:
			team_1_spawn_points.append(spawn_point.global_position)
	
	for spawn_point in spawn_group_2:
		if spawn_point is Node3D:
			team_2_spawn_points.append(spawn_point.global_position)
	
	# Generate default spawn points if none found
	if team_1_spawn_points.is_empty():
		_generate_default_spawn_points()

func _generate_default_spawn_points():
	# Generate spawn points in opposing corners
	var map_size = Vector3(100, 0, 100)
	
	# Team 1 spawns (left side)
	for i in range(max_team_size):
		var spawn_pos = Vector3(
			-map_size.x * 0.4 + randf_range(-10, 10),
			2,
			randf_range(-map_size.z * 0.3, map_size.z * 0.3)
		)
		team_1_spawn_points.append(spawn_pos)
	
	# Team 2 spawns (right side)
	for i in range(max_team_size):
		var spawn_pos = Vector3(
			map_size.x * 0.4 + randf_range(-10, 10),
			2,
			randf_range(-map_size.z * 0.3, map_size.z * 0.3)
		)
		team_2_spawn_points.append(spawn_pos)

func _spawn_initial_teams():
	print("Spawning initial teams...")
	
	# Spawn Team 1
	for i in range(max_team_size):
		_spawn_agent(1, i)
	
	# Spawn Team 2
	for i in range(max_team_size):
		_spawn_agent(2, i)
	
	game_active = true
	agents_spawned.emit()
	print("Teams spawned. Game active.")

func _spawn_agent(team_id: int, agent_index: int):
	if not agent_scene:
		push_error("Agent scene not set in FPSGameManager")
		return
	
	var agent = agent_scene.instantiate() as ModernFPSAgent
	if not agent:
		push_error("Agent scene does not contain ModernFPSAgent")
		return
	
	# Set spawn position
	var spawn_points = team_1_spawn_points if team_id == 1 else team_2_spawn_points
	if spawn_points.is_empty():
		push_error("No spawn points available for team " + str(team_id))
		return
	
	var spawn_index = agent_index % spawn_points.size()
	var spawn_pos = spawn_points[spawn_index]
	
	# Add small random offset to avoid agents spawning on top of each other
	spawn_pos += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	
	# Validate spawn position on navmesh
	var nav_map = navigation_region.get_navigation_map()
	var valid_spawn_pos = NavigationServer3D.map_get_closest_point(nav_map, spawn_pos)
	
	agent.global_position = valid_spawn_pos
	agent.team_id = team_id
	agent.name = "Agent_Team" + str(team_id) + "_" + str(agent_index)
	
	# Randomize agent personality
	_randomize_agent_personality(agent)
	
	# Add to scene and register
	add_child(agent)
	entity_manager.add(agent)
	all_agents.append(agent)
	
	if team_id == 1:
		team_1_agents.append(agent)
	else:
		team_2_agents.append(agent)
	
	# Connect death signal for respawning
	agent.on_death.connect(_on_agent_death.bind(agent))
	
	print("Spawned agent: ", agent.name, " at position: ", valid_spawn_pos)

func _randomize_agent_personality(agent: ModernFPSAgent):
	# Randomize behavior parameters for variety
	agent.aggression = randf_range(0.3, 0.9)
	agent.accuracy = randf_range(0.6, 0.9)
	agent.reaction_time = randf_range(0.1, 0.4)
	agent.risk_tolerance = randf_range(0.2, 0.8)
	agent.team_loyalty = randf_range(0.7, 1.0)
	
	# Adjust movement speed based on personality
	var base_speed = randf_range(4.0, 6.0)
	agent.movement_speed = base_speed
	agent.sprint_speed = base_speed * randf_range(1.4, 1.8)
	agent.crouch_speed = base_speed * randf_range(0.4, 0.6)

func _process(delta):
	if not game_active:
		return
	
	game_time += delta
	
	# Update entity manager
	if entity_manager:
		entity_manager.update(delta)
	
	# Debug visualization
	if enable_debug_visualization:
		_update_debug_visualization()

func _update_debug_visualization():
	# This could show agent states, targets, paths, etc.
	# For now, just print occasional status
	if fmod(game_time, 5.0) < 0.1:  # Every 5 seconds
		_print_game_status()

func _print_game_status():
	var active_agents = all_agents.filter(func(agent): return agent.health > 0)
	var team_1_alive = team_1_agents.filter(func(agent): return agent.health > 0)
	var team_2_alive = team_2_agents.filter(func(agent): return agent.health > 0)
	
	print("Game Status - Time: %.1f | Team 1: %d alive | Team 2: %d alive" % [
		game_time, team_1_alive.size(), team_2_alive.size()
	])

func _on_agent_death(agent: ModernFPSAgent):
	print("Agent died: ", agent.name)
	
	# Schedule respawn
	var timer = get_tree().create_timer(respawn_time)
	await timer.timeout
	
	if is_instance_valid(agent):
		_respawn_agent(agent)

func _respawn_agent(agent: ModernFPSAgent):
	if not is_instance_valid(agent):
		return
	
	# Find appropriate spawn point
	var spawn_points = team_1_spawn_points if agent.team_id == 1 else team_2_spawn_points
	var spawn_pos = spawn_points.pick_random()
	
	# Add random offset
	spawn_pos += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	
	# Validate on navmesh
	var nav_map = navigation_region.get_navigation_map()
	var valid_spawn_pos = NavigationServer3D.map_get_closest_point(nav_map, spawn_pos)
	
	# Reset agent
	agent.global_position = valid_spawn_pos
	agent.health = agent.max_health
	agent.current_target = null
	agent.stress_level = 0.0
	
	# Reset health system
	if agent.health_system:
		agent.health_system.current_health = agent.health_system.max_health
	
	# Reset state machine
	if agent.state_machine:
		agent.state_machine.change_state_by_name("patrol")
	
	print("Respawned agent: ", agent.name, " at position: ", valid_spawn_pos)

# Squad management functions
func create_squad(team_id: int, agent_indices: Array[int]) -> SquadCoordination:
	var team_agents = team_1_agents if team_id == 1 else team_2_agents
	var squad_members: Array[ModernFPSAgent] = []
	
	for index in agent_indices:
		if index < team_agents.size():
			squad_members.append(team_agents[index])
	
	var squad = SquadCoordination.new(squad_members)
	return squad

func get_team_agents(team_id: int) -> Array[ModernFPSAgent]:
	return team_1_agents if team_id == 1 else team_2_agents

func get_all_active_agents() -> Array[ModernFPSAgent]:
	return all_agents.filter(func(agent): return agent.health > 0)

# Navigation utility functions
func is_position_on_navmesh(position: Vector3) -> bool:
	var nav_map = navigation_region.get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(nav_map, position)
	return closest_point.distance_to(position) < 2.0

func get_random_navmesh_position(center: Vector3 = Vector3.ZERO, radius: float = 50.0) -> Vector3:
	var nav_map = navigation_region.get_navigation_map()
	
	# Try to find a valid position
	for attempt in range(10):
		var random_pos = center + Vector3(
			randf_range(-radius, radius),
			0,
			randf_range(-radius, radius)
		)
		
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, random_pos)
		if closest_point.distance_to(random_pos) < 5.0:
			return closest_point
	
	# Fallback to center
	return NavigationServer3D.map_get_closest_point(nav_map, center)

# Objective management
func set_team_objective(team_id: int, objective_position: Vector3):
	var team_agents = get_team_agents(team_id)
	
	for agent in team_agents:
		if agent.health > 0:
			# Add objective goal to agent's evaluators
			if agent.think_goal:
				# Clear existing objective evaluators
				for evaluator in agent.think_goal.evaluators:
					if evaluator is ObjectiveEvaluator:
						agent.think_goal.evaluators.erase(evaluator)
				
				# Add new objective
				agent.think_goal.add_evaluator(ObjectiveEvaluator.new(objective_position))

func rebake_navigation_mesh():
	if navigation_region and navigation_mesh:
		navigation_region.bake_navigation_mesh()
		print("Navigation mesh rebaked")
