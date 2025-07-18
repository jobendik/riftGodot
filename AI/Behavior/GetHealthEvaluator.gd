extends GoalEvaluator
class_name GetHealthEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.0
	var health_ratio = agent.health / agent.max_health
	
	if health_ratio < 0.5:
		desirability = (1.0 - health_ratio) * 0.8
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	agent.state_machine.change_state_by_name("heal")
