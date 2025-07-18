extends GoalEvaluator
class_name ExploreEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.3
	
	if not agent.current_target:
		desirability = 0.6
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	agent.state_machine.change_state_by_name("patrol")
