# Modern FPS Game Manager - Handles AI agents with proper navigation setup
extends Node3D
class_name ModernFPSGameManager

@export var agent_scene: PackedScene
@export var player_scene: PackedScene
@export var max_team_size: int = 4  # Reduced to 4 to accommodate human player
@export var respawn_time: float = 5.0
@export var enable_debug_visualization: bool = true
@export var spawn_human_player: bool = true
@export var enable_friendly_fire: bool = false

# Navigation setup - made optional
var navigation_region: NavigationRegion3D = null
var navigation_mesh: NavigationMesh

# Agent management
var entity_manager: EntityManager
var team_1_agents: Array[FullyIntegratedFPSAgent] = []
var team_2_agents: Array[FullyIntegratedFPSAgent] = []
var all_agents: Array[FullyIntegratedFPSAgent] = []

# Spawn points - should be set up in the scene or generated
var team_1_spawn_points: Array[Vector3] = []
var team_2_spawn_points: Array[Vector3] = []

# Game state
var game_active: bool = false
var game_time: float = 0.0

signal agents_spawned
signal navigation_ready

func _ready():
	print("DEBUG: ModernFPSGameManager _ready() called")
	
	# Add to group so agents can find the game manager
	add_to_group("game_manager")
	
	_find_or_create_navigation_region()
	_initialize_navigation()
	_initialize_entity_manager()
	_setup_spawn_points()
	
	# Wait for navigation to be ready before spawning agents
	if navigation_region:
		# Wait one frame for navigation to initialize
		await get_tree().process_frame
		_wait_for_navigation_ready()
	else:
		print("WARNING: No navigation region available, spawning without navigation")
		_spawn_initial_teams()

func _find_or_create_navigation_region():
	# First try to find NavigationRegion3D in the scene
	navigation_region = get_node_or_null("NavigationRegion3D")
	
	if not navigation_region:
		# Try to find it in parent (Main scene)
		navigation_region = get_parent().get_node_or_null("NavigationRegion3D")
	
	if not navigation_region:
		print("DEBUG: Creating new NavigationRegion3D")
		# Create navigation region if it doesn't exist
		navigation_region = NavigationRegion3D.new()
		navigation_region.name = "NavigationRegion3D"
		get_parent().add_child(navigation_region)
	else:
		print("DEBUG: Found existing NavigationRegion3D at: ", navigation_region.get_path())

func _wait_for_navigation_ready():
	print("DEBUG: Waiting for navigation to be ready...")
	if not navigation_region:
		push_error("No NavigationRegion3D found!")
		return
	
	var nav_map = navigation_region.get_navigation_map()
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		print("DEBUG: Waiting for navigation map to be ready...")
		await get_tree().process_frame
	
	print("DEBUG: Navigation map is ready")
	navigation_ready.emit()
	_spawn_initial_teams()

func _initialize_navigation():
	if not navigation_region:
		print("WARNING: No navigation region available")
		return
	
	# Set up navigation mesh if not already configured
	if not navigation_region.navigation_mesh:
		navigation_mesh = NavigationMesh.new()
		
		# Configure navigation mesh for FPS gameplay
		# FIXED: Use consistent cell_height with navigation map (0.25)
		navigation_mesh.cell_size = 0.25
		navigation_mesh.cell_height = 0.25  # Changed from 0.1 to 0.25
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
	else:
		print("DEBUG: Using existing navigation mesh")

func _initialize_entity_manager():
	entity_manager = EntityManager.new()
	add_child(entity_manager)
	print("DEBUG: Entity manager initialized")

func _setup_spawn_points():
	print("DEBUG: Setting up spawn points...")
	
	# Look for spawn point nodes in the scene
	var spawn_group_1 = get_tree().get_nodes_in_group("team_1_spawn")
	var spawn_group_2 = get_tree().get_nodes_in_group("team_2_spawn")
	
	print("DEBUG: Found ", spawn_group_1.size(), " team 1 spawn points")
	print("DEBUG: Found ", spawn_group_2.size(), " team 2 spawn points")
	
	for spawn_point in spawn_group_1:
		if spawn_point is Node3D:
			team_1_spawn_points.append(spawn_point.global_position)
			print("DEBUG: Team 1 spawn point at: ", spawn_point.global_position)
	
	for spawn_point in spawn_group_2:
		if spawn_point is Node3D:
			team_2_spawn_points.append(spawn_point.global_position)
			print("DEBUG: Team 2 spawn point at: ", spawn_point.global_position)
	
	# Generate default spawn points if none found
	if team_1_spawn_points.is_empty():
		print("DEBUG: No spawn points found, generating defaults")
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
	
	print("DEBUG: Generated ", team_1_spawn_points.size(), " spawn points for Team 1")
	print("DEBUG: Generated ", team_2_spawn_points.size(), " spawn points for Team 2")

func _spawn_initial_teams():
	print("DEBUG: Starting team spawn process...")
	print("DEBUG: Max team size: ", max_team_size)
	print("DEBUG: Team 1 spawn points: ", team_1_spawn_points.size())
	print("DEBUG: Team 2 spawn points: ", team_2_spawn_points.size())
	
	# Spawn Team 1 (3 AI agents + 1 human player)
	var team_1_ai_count = max_team_size - 1 if spawn_human_player else max_team_size
	for i in range(team_1_ai_count):
		print("DEBUG: Spawning Team 1 agent ", i)
		_spawn_agent(1, i)
		print("DEBUG: Team 1 agents count: ", team_1_agents.size())
	
	# Spawn human player for Team 1
	if spawn_human_player:
		_spawn_human_player()
	
	# Spawn Team 2 (full enemy team)
	for i in range(max_team_size):
		print("DEBUG: Spawning Team 2 agent ", i)
		_spawn_agent(2, i)
		print("DEBUG: Team 2 agents count: ", team_2_agents.size())
	
	print("DEBUG: Final counts - Team 1: ", team_1_agents.size(), " Team 2: ", team_2_agents.size())
	print("DEBUG: All agents: ", all_agents.size())
	
	game_active = true
	agents_spawned.emit()
	print("Teams spawned. Game active.")

func _spawn_agent(team_id: int, agent_index: int):
	print("DEBUG: Attempting to spawn agent for team ", team_id, " index ", agent_index)
	
	if not agent_scene:
		push_error("Agent scene not set in FPSGameManager")
		print("ERROR: agent_scene is null!")
		return
	
	print("DEBUG: Agent scene is set: ", agent_scene.resource_path)
	
	var agent = agent_scene.instantiate() as FullyIntegratedFPSAgent
	if not agent:
		push_error("Agent scene does not contain FullyIntegratedFPSAgent")
		print("ERROR: Failed to instantiate agent or wrong type")
		return
	
	print("DEBUG: Agent instantiated successfully: ", agent.name)
	
	# Set spawn position
	var spawn_points = team_1_spawn_points if team_id == 1 else team_2_spawn_points
	if spawn_points.is_empty():
		push_error("No spawn points available for team " + str(team_id))
		print("ERROR: No spawn points for team ", team_id)
		agent.queue_free()
		return
	
	var spawn_index = agent_index % spawn_points.size()
	var spawn_pos = spawn_points[spawn_index]
	
	# Add small random offset to avoid agents spawning on top of each other
	spawn_pos += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	
	# Set basic properties before adding to scene
	agent.team_id = team_id
	agent.name = "Agent_Team" + str(team_id) + "_" + str(agent_index)
	
	# FIXED: Add to scene tree BEFORE accessing global_position
	add_child(agent)
	print("DEBUG: Agent added to scene tree")
	
	# Now we can safely set the position
	if navigation_region:
		# Validate spawn position on navmesh
		var nav_map = navigation_region.get_navigation_map()
		var valid_spawn_pos = NavigationServer3D.map_get_closest_point(nav_map, spawn_pos)
		agent.global_position = valid_spawn_pos
		print("DEBUG: Agent positioned at: ", valid_spawn_pos)
	else:
		agent.global_position = spawn_pos
		print("DEBUG: Agent positioned at: ", spawn_pos, " (no navigation)")
	
	# Randomize agent personality
	_randomize_agent_personality(agent)
	
	# Register with entity manager
	if entity_manager:
		entity_manager.add(agent)
	
	all_agents.append(agent)
	
	if team_id == 1:
		team_1_agents.append(agent)
	else:
		team_2_agents.append(agent)
	
	# Connect death signal for respawning
	agent.on_death.connect(_on_agent_death.bind(agent))
	
	print("DEBUG: Spawned agent: ", agent.name, " at position: ", agent.global_position)

func _spawn_human_player():
	print("DEBUG: Spawning human player for Team 1")
	
	if not player_scene:
		print("WARNING: No player scene set, skipping human player spawn")
		return
	
	var human_player = player_scene.instantiate()
	if not human_player:
		print("ERROR: Failed to instantiate human player")
		return
	
	# Set spawn position for human player
	var spawn_pos = team_1_spawn_points[0] if not team_1_spawn_points.is_empty() else Vector3.ZERO
	spawn_pos += Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	
	# Set human player properties
	human_player.name = "HumanPlayer_Team1"
	
	# Add to scene
	add_child(human_player)
	
	# Position the player
	if navigation_region:
		var nav_map = navigation_region.get_navigation_map()
		var valid_spawn_pos = NavigationServer3D.map_get_closest_point(nav_map, spawn_pos)
		human_player.global_position = valid_spawn_pos
		print("DEBUG: Human player positioned at: ", valid_spawn_pos)
	else:
		human_player.global_position = spawn_pos
		print("DEBUG: Human player positioned at: ", spawn_pos, " (no navigation)")
	
	# Register with entity manager if the player is a GameEntity
	if human_player is GameEntity:
		human_player.team_id = 1  # Team 1
		if entity_manager:
			entity_manager.add(human_player)
		print("DEBUG: Human player registered with entity manager")
	
	print("DEBUG: Human player spawned successfully")

func _randomize_agent_personality(agent: FullyIntegratedFPSAgent):
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
	var active_agents = all_agents.filter(func(agent): return is_instance_valid(agent) and agent.health > 0)
	var team_1_alive = team_1_agents.filter(func(agent): return is_instance_valid(agent) and agent.health > 0)
	var team_2_alive = team_2_agents.filter(func(agent): return is_instance_valid(agent) and agent.health > 0)
	
	print("Game Status - Time: %.1f | Team 1: %d alive | Team 2: %d alive" % [
		game_time, team_1_alive.size(), team_2_alive.size()
	])

func _on_agent_death(agent: FullyIntegratedFPSAgent):
	print("Agent died: ", agent.name)
	
	# Schedule respawn
	var timer = get_tree().create_timer(respawn_time)
	await timer.timeout
	
	if is_instance_valid(agent):
		_respawn_agent(agent)

func _respawn_agent(agent: FullyIntegratedFPSAgent):
	if not is_instance_valid(agent):
		return
	
	# Find appropriate spawn point
	var spawn_points = team_1_spawn_points if agent.team_id == 1 else team_2_spawn_points
	var spawn_pos = spawn_points.pick_random()
	
	# Add random offset
	spawn_pos += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	
	if navigation_region:
		# Validate on navmesh
		var nav_map = navigation_region.get_navigation_map()
		var valid_spawn_pos = NavigationServer3D.map_get_closest_point(nav_map, spawn_pos)
		agent.global_position = valid_spawn_pos
	else:
		agent.global_position = spawn_pos
	
	# Reset agent
	agent.health = agent.max_health
	agent.current_target = null
	agent.stress_level = 0.0
	
	# Reset health system
	if agent.health_system:
		agent.health_system.current_health = agent.health_system.max_health
	
	# Reset state machine
	if agent.state_machine:
		agent.state_machine.change_state_by_name("patrol")
	
	print("Respawned agent: ", agent.name, " at position: ", agent.global_position)

# Squad management functions
func create_squad(team_id: int, agent_indices: Array[int]) -> SquadCoordination:
	var team_agents = team_1_agents if team_id == 1 else team_2_agents
	var squad_members: Array[FullyIntegratedFPSAgent] = []
	
	for index in agent_indices:
		if index < team_agents.size():
			squad_members.append(team_agents[index])
	
	var squad = SquadCoordination.new(squad_members)
	return squad

func get_team_agents(team_id: int) -> Array[FullyIntegratedFPSAgent]:
	return team_1_agents if team_id == 1 else team_2_agents

func get_all_active_agents() -> Array[FullyIntegratedFPSAgent]:
	return all_agents.filter(func(agent): return is_instance_valid(agent) and agent.health > 0)

# Navigation utility functions
func is_position_on_navmesh(position: Vector3) -> bool:
	if not navigation_region:
		return false
		
	var nav_map = navigation_region.get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(nav_map, position)
	return closest_point.distance_to(position) < 2.0

func get_random_navmesh_position(center: Vector3 = Vector3.ZERO, radius: float = 50.0) -> Vector3:
	if not navigation_region:
		return center
		
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
		if is_instance_valid(agent) and agent.health > 0:
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
