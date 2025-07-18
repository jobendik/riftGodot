# Learning and Adaptation System
extends RefCounted
class_name LearningSystem

var owner_agent: FullyIntegratedFPSAgent
var combat_memory: Dictionary = {} # enemy_id -> CombatProfile
var learn_rate: float = 0.1

class CombatProfile extends RefCounted:
	var enemy_id: String
	var times_encountered: int = 0
	var times_defeated: int = 0 # Times we defeated them
	var times_killed_by: int = 0 # Times they defeated us

func _init(agent: FullyIntegratedFPSAgent):
	owner_agent = agent

func learn_from_combat(enemy: FullyIntegratedFPSAgent, outcome: String) -> void:
	if not is_instance_valid(enemy): return
	
	if not enemy.uuid in combat_memory:
		combat_memory[enemy.uuid] = CombatProfile.new()
		combat_memory[enemy.uuid].enemy_id = enemy.uuid
	
	var profile = combat_memory[enemy.uuid]
	profile.times_encountered += 1
	
	match outcome:
		"victory":
			profile.times_defeated += 1
			# Become slightly more aggressive after a win
			owner_agent.aggression = min(1.0, owner_agent.aggression + 0.05 * learn_rate)
		"defeat":
			profile.times_killed_by += 1
			# Become slightly less aggressive after a loss
			owner_agent.aggression = max(0.1, owner_agent.aggression - 0.05 * learn_rate)

func learn_from_damage(attacker: FullyIntegratedFPSAgent, damage: float):
	# Become less risk-tolerant if taking heavy damage
	if damage > 30:
		owner_agent.risk_tolerance = max(0.1, owner_agent.risk_tolerance - 0.1 * learn_rate)

func adapt_strategy(enemy: FullyIntegratedFPSAgent) -> void:
	if not is_instance_valid(enemy) or not enemy.uuid in combat_memory:
		return
	
	var profile = combat_memory[enemy.uuid]
	# If we've been killed by this enemy a lot, lower our risk tolerance when fighting them
	if profile.times_killed_by > profile.times_defeated + 1:
		owner_agent.risk_tolerance = max(0.1, owner_agent.risk_tolerance - 0.2)
