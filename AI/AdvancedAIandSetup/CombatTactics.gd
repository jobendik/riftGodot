# Advanced Combat Tactics
extends RefCounted
class_name CombatTactics

enum TacticType {
	RUSH,
	DEFENSIVE,
	FLANKING,
	SUPPRESSIVE,
	AMBUSH,
	RETREAT,
	SNIPER
}

var owner_agent: FPSAgent
var current_tactic: TacticType = TacticType.DEFENSIVE
var tactic_timer: float = 0.0
var tactic_duration: float = 5.0

func _init(agent: FPSAgent):
	owner_agent = agent

func select_tactic(situation: Dictionary) -> TacticType:
	var threat_level = situation.get("threat_level", 0.5)
	var tactical_advantage = situation.get("tactical_advantage", 0.5)
	var aggression = owner_agent.get("aggression", 0.5)

	# Decision logic for choosing a tactic
	if threat_level > 0.8 and tactical_advantage < 0.3:
		return TacticType.RETREAT
	if threat_level < 0.3 and aggression > 0.7:
		return TacticType.RUSH
	if tactical_advantage > 0.7:
		if owner_agent.weapon_system and owner_agent.weapon_system.current_weapon.name == "Sniper":
			return TacticType.SNIPER
		elif aggression > 0.6:
			return TacticType.FLANKING
		else:
			return TacticType.SUPPRESSIVE
	
	return TacticType.DEFENSIVE

func execute_tactic(delta: float) -> void:
	tactic_timer += delta
	
	if tactic_timer > tactic_duration:
		# Periodically re-evaluate the chosen tactic
		var analyzer = TacticalAnalyzer.new(owner_agent)
		var situation = analyzer.analyze_situation()
		current_tactic = select_tactic(situation)
		tactic_timer = 0.0
	
	# The actual execution of these tactics is handled by the agent's states
	# (e.g., CombatState, FlankingState, RetreatState)
