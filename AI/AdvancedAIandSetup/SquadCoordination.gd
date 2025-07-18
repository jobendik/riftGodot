# Squad Coordination System
extends RefCounted
class_name SquadCoordination

var squad_members: Array[FullyIntegratedFPSAgent] = []
var squad_leader: FullyIntegratedFPSAgent
var formation: String = "wedge"
var squad_target: GameEntity

func _init(members: Array[FullyIntegratedFPSAgent]):
	squad_members = members
	if not squad_members.is_empty():
		squad_leader = squad_members[0]

func coordinate_attack(target: GameEntity) -> void:
	squad_target = target
	
	# Assign roles to squad members for a coordinated attack
	for i in range(squad_members.size()):
		var member = squad_members[i]
		if not is_instance_valid(member): continue
		
		if i == 0: # Leader engages directly
			member.current_target = target
		elif i < squad_members.size() / 2: # Half the squad flanks
			member.state_machine.change_state_by_name("flanking")
		else: # The rest provide suppressive fire
			member.current_target = target
			# A "suppressive_fire" state or tactic would be needed for full implementation
			
func request_support(requesting_agent: FullyIntegratedFPSAgent) -> void:
	# Find the nearest available squad member to help
	var nearest_available = find_nearest_available_member(requesting_agent.global_position)
	if nearest_available:
		# Send the available member to the requesting agent's position
		nearest_available.think_goal.remove_all_subgoals()
		var move_goal = MoveToPositionGoal.new(nearest_available, requesting_agent.global_position)
		nearest_available.think_goal.add_subgoal(move_goal)

func find_nearest_available_member(position: Vector3) -> FullyIntegratedFPSAgent:
	var nearest: FullyIntegratedFPSAgent = null
	var min_distance_sq = INF
	
	for member in squad_members:
		if is_instance_valid(member) and not member.current_target: # Find members not in combat
			var distance_sq = member.global_position.distance_squared_to(position)
			if distance_sq < min_distance_sq:
				min_distance_sq = distance_sq
				nearest = member
	
	return nearest
