# ==============================================
# ThinkGoal.gd
# Location: AI/Behavior/ThinkGoal.gd
# ==============================================
extends CompositeGoal
class_name ThinkGoal

var evaluators: Array[GoalEvaluator] = []

func _init(entity: GameEntity):
	owner = entity

func add_evaluator(evaluator: GoalEvaluator) -> void:
	evaluators.append(evaluator)

func activate() -> void:
	status = Status.ACTIVE
	arbitrate()

func process(delta: float) -> Status:
	activate_if_inactive()
	
	var subgoal_status = process_subgoals(delta)
	
	if subgoal_status == Status.COMPLETED and subgoals.is_empty():
		status = Status.COMPLETED
	elif subgoal_status == Status.FAILED:
		status = Status.FAILED
	
	return status

func arbitrate() -> void:
	var best_evaluator: GoalEvaluator = null
	var best_score = 0.0
	
	for evaluator in evaluators:
		var score = evaluator.calculate_desirability(owner)
		if score > best_score:
			best_score = score
			best_evaluator = evaluator
	
	if best_evaluator and best_score > 0.3:
		best_evaluator.set_goal(owner)

# ==============================================
# GoalEvaluator.gd (Base class)
# Location: AI/Behavior/GoalEvaluator.gd
# ==============================================
extends RefCounted
class_name GoalEvaluator

var characterization_bias: float = 1.0

func calculate_desirability(owner: GameEntity) -> float:
	return 0.0

func set_goal(owner: GameEntity) -> void:
	pass

# ==============================================
# AttackEvaluator.gd
# Location: AI/Behavior/AttackEvaluator.gd
# ==============================================
extends GoalEvaluator
class_name AttackEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return 0.0
	
	var desirability = 0.0
	
	if agent.current_target:
		desirability = 0.8 * agent.aggression
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent and agent.current_target:
		agent.think_goal.remove_all_subgoals()
		agent.think_goal.add_subgoal(AttackGoal.new(agent, agent.current_target))

# ==============================================
# ExploreEvaluator.gd
# Location: AI/Behavior/ExploreEvaluator.gd
# ==============================================
extends GoalEvaluator
class_name ExploreEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return 0.0
	
	var desirability = 0.3
	
	if not agent.current_target:
		desirability = 0.6
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.state_machine.change_state_by_name("patrol")

# ==============================================
# GetHealthEvaluator.gd
# Location: AI/Behavior/GetHealthEvaluator.gd
# ==============================================
extends GoalEvaluator
class_name GetHealthEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return 0.0
	
	var desirability = 0.0
	var health_ratio = agent.health / agent.max_health
	
	if health_ratio < 0.5:
		desirability = (1.0 - health_ratio) * 0.8
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.state_machine.change_state_by_name("heal")

# ==============================================
# GetWeaponEvaluator.gd
# Location: AI/Behavior/GetWeaponEvaluator.gd
# ==============================================
extends GoalEvaluator
class_name GetWeaponEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return 0.0
	
	var desirability = 0.0
	
	if not agent.weapon_system.current_weapon_slot:
		desirability = 0.9
	elif agent.weapon_system.get_current_ammo() <= 0 and agent.weapon_system.get_reserve_ammo() <= 0:
		desirability = 0.7
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.state_machine.change_state_by_name("pickup_weapon")

# ==============================================
# HelpTeammateEvaluator.gd
# Location: AI/Behavior/HelpTeammateEvaluator.gd
# ==============================================
extends GoalEvaluator
class_name HelpTeammateEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return 0.0
	
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

# ==============================================
# AttackGoal.gd
# Location: AI/Behavior/AttackGoal.gd
# ==============================================
extends Goal
class_name AttackGoal

var target: FullyIntegratedFPSAgent

func _init(entity: GameEntity, target_entity: FullyIntegratedFPSAgent):
	owner = entity
	target = target_entity

func activate() -> void:
	status = Status.ACTIVE

func process(delta: float) -> Status:
	activate_if_inactive()
	
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not is_instance_valid(target):
		status = Status.FAILED
		return status
	
	# Switch to combat state
	agent.state_machine.change_state_by_name("combat")
	
	if target.health <= 0:
		status = Status.COMPLETED
	
	return status

# ==============================================
# WeaponSelectionFuzzy.gd
# Location: AI/FuzzyLogic/WeaponSelectionFuzzy.gd
# ==============================================
extends RefCounted
class_name WeaponSelectionFuzzy

var distance_var: FuzzyVariable
var ammo_var: FuzzyVariable
var weapon_var: FuzzyVariable

func _init():
	_setup_fuzzy_variables()

func _setup_fuzzy_variables():
	# Distance fuzzy variable
	distance_var = FuzzyVariable.new("distance")
	distance_var.add_set("close", TriangleFuzzySet.new(5, 5, 10))
	distance_var.add_set("medium", TriangleFuzzySet.new(20, 15, 15))
	distance_var.add_set("far", TriangleFuzzySet.new(50, 30, 20))
	
	# Ammo fuzzy variable
	ammo_var = FuzzyVariable.new("ammo")
	ammo_var.add_set("low", TriangleFuzzySet.new(0, 0, 30))
	ammo_var.add_set("medium", TriangleFuzzySet.new(50, 30, 30))
	ammo_var.add_set("high", TriangleFuzzySet.new(100, 50, 0))
	
	# Weapon preference fuzzy variable
	weapon_var = FuzzyVariable.new("weapon")
	weapon_var.add_set("pistol", TriangleFuzzySet.new(0.3, 0.3, 0.4))
	weapon_var.add_set("rifle", TriangleFuzzySet.new(0.7, 0.3, 0.3))
	weapon_var.add_set("shotgun", TriangleFuzzySet.new(0.2, 0.2, 0.3))

func select_weapon(distance: float, ammo_level: float) -> String:
	# Simple weapon selection based on distance
	if distance < 10:
		return "shotgun"
	elif distance < 30:
		return "rifle"
	else:
		return "rifle"  # Default to rifle for long range