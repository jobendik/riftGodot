# Custom Evaluator - Objective Priority
extends GoalEvaluator
class_name ObjectiveEvaluator

var objective_position: Vector3

func _init(obj_pos: Vector3):
	objective_position = obj_pos

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FPSAgent
	if not agent: return 0.0
	
	var desirability = 0.4
	
	# Desirability is higher the closer the agent is to the objective
	var distance = agent.global_position.distance_to(objective_position)
	desirability += (100.0 - min(distance, 100.0)) / 200.0
	
	# Factor in team loyalty
	desirability *= agent.team_loyalty
	
	# Less desirable if currently in combat
	if agent.current_target:
		desirability *= 0.5
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if agent:
		agent.think_goal.remove_all_subgoals()
		agent.think_goal.add_subgoal(CaptureObjectiveGoal.new(agent, objective_position))
