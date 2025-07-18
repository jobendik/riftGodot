# Game Manager Example - Managing multiple AI agents
extends Node3D
class_name FPSGameManager

var entity_manager: EntityManager
var team_1_agents: Array[FPSAgent] = []
var team_2_agents: Array[FPSAgent] = []

@export var agent_scene: PackedScene

func _ready():
	# Create and add the entity manager to the scene
	entity_manager = EntityManager.new()
	add_child(entity_manager)
	
	# Spawn the teams
	spawn_team(1, Vector3(-20, 0, 0), 5)
	spawn_team(2, Vector3(20, 0, 0), 5)

func _process(delta: float):
	# The entity manager handles updating all registered agents
	if entity_manager:
		entity_manager.update(delta)

func spawn_team(team_id: int, base_position: Vector3, count: int):
	if not agent_scene:
		printerr("Agent scene not set in FPSGameManager.")
		return

	for i in range(count):
		var offset = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		var agent = agent_scene.instantiate() as FPSAgent
		if agent:
			agent.global_position = base_position + offset
			agent.team_id = team_id
			
			if team_id == 1:
				team_1_agents.append(agent)
			else:
				team_2_agents.append(agent)
			
			# Add the agent to the scene and the entity manager
			add_child(agent)
			entity_manager.add(agent)
