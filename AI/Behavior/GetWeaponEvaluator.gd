extends GoalEvaluator
class_name GetWeaponEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return 0.0
	
	var desirability = 0.0
	
	if not agent.weapon_system.current_weapon_slot:
		desirability = 0.9
	elif agent.weapon_system.get_current_ammo() <= 0 and agent.weapon_system.get_reserve_ammo() <= 0:
		desirability = 0.7
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	agent.state_machine.change_state_by_name("pickup_weapon")
