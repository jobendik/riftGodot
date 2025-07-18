# Example Game Mode Manager
extends Node3D
class_name FPSGameMode

@export var agent_scene: PackedScene
@export var max_team_size: int = 8
@export var respawn_time: float = 5.0

var entity_manager: EntityManager
var sound_manager: SoundManager

func _ready():
	entity_manager = EntityManager.new()
	add_child(entity_manager)
	sound_manager = SoundManager.new()
	add_child(sound_manager)
	
	spawn_teams()

func spawn_teams():
	for i in range(max_team_size):
		spawn_agent(1)
		spawn_agent(2)

func spawn_agent(team_id: int):
	if not agent_scene: return
	
	var spawn_points = get_tree().get_nodes_in_group("spawn_team_" + str(team_id))
	if spawn_points.is_empty(): return
	
	var spawn_point = spawn_points.pick_random() as Node3D
	var agent = agent_scene.instantiate() as HumanLikeFPSAgent
	
	agent.global_position = spawn_point.global_position
	agent.team_id = team_id
	
	add_child(agent)
	entity_manager.add(agent)
	agent.on_death.connect(_on_agent_death.bind(agent))

func _on_agent_death(agent: HumanLikeFPSAgent):
	var timer = get_tree().create_timer(respawn_time)
	await timer.timeout
	var team_id = agent.team_id
	if is_instance_valid(agent):
		agent.queue_free()
	spawn_agent(team_id)
