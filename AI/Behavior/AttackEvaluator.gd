extends GoalEvaluator
class_name AttackEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.0
	
	if agent.current_target:
		desirability = 0.8 * agent.aggression
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not agent.current_target:
		return
	
	agent.think_goal.remove_all_subgoals()
	agent.think_goal.add_subgoal(AttackGoal.new(agent, agent.current_target))
