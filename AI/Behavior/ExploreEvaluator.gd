extends GoalEvaluator
class_name ExploreEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.8  # Much more aggressive exploration
	
	# Even higher priority if no target and no recent combat
	if not agent.current_target:
		desirability = 0.9
		
		# Boost if we haven't seen enemies in a while
		if agent.time_since_last_enemy_seen > 10.0:
			desirability = 0.95
	
	# Lower priority if we're currently engaging
	if agent.current_target:
		desirability = 0.2
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	agent.state_machine.change_state_by_name("patrol")
