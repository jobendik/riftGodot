extends GoalEvaluator
class_name HelpTeammateEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.0
	
	# Check for nearby teammates in trouble
	for neighbor in agent.neighbors:
		var teammate = neighbor as FullyIntegratedFPSAgent
		if teammate and teammate.team_id == agent.team_id:
			if teammate.health < teammate.max_health * 0.3:
				desirability = 0.5 * agent.team_loyalty
				break
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	# Implementation would involve moving to help teammate
	pass
