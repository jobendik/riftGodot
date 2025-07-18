# Tactical Analysis System
extends RefCounted
class_name TacticalAnalyzer

var owner_agent: FPSAgent

func _init(agent: FPSAgent):
	owner_agent = agent

func analyze_situation() -> Dictionary:
	var analysis = {
		"threat_level": calculate_threat_level(),
		"tactical_advantage": calculate_tactical_advantage(),
		"suggested_action": "",
		"flanking_routes": [], # Placeholder
		"choke_points": []   # Placeholder
	}
	
	# Determine a suggested action based on the analysis
	if analysis.threat_level > 0.7:
		analysis.suggested_action = "retreat" if analysis.tactical_advantage < 0.3 else "defensive"
	elif analysis.threat_level > 0.4:
		analysis.suggested_action = "aggressive" if analysis.tactical_advantage > 0.6 else "cautious"
	else:
		analysis.suggested_action = "advance"
	
	return analysis

func calculate_threat_level() -> float:
	var threat = 0.0
	var enemy_count = 0
	
	# Count visible enemies
	if owner_agent.vision_system:
		for entity in owner_agent.vision_system.visible_entities:
			var enemy = entity as FPSAgent
			if enemy and enemy.team_id != owner_agent.team_id:
				enemy_count += 1
	
	# Threat increases with low health and more enemies
	threat += (1.0 - (owner_agent.health / owner_agent.max_health)) * 0.4
	threat += min(enemy_count * 0.2, 0.6)
	
	return clamp(threat, 0.0, 1.0)

func calculate_tactical_advantage() -> float:
	var advantage = 0.5 # Start at a neutral value
	
	# Height advantage
	if owner_agent.current_target:
		var height_diff = owner_agent.global_position.y - owner_agent.current_target.global_position.y
		advantage += clamp(height_diff * 0.1, -0.2, 0.2)
	
	# Advantage increases with nearby allies
	advantage += min(count_nearby_allies() * 0.15, 0.3)
	
	# Advantage is affected by ammo status
	if owner_agent.weapon_system and owner_agent.weapon_system.current_weapon:
		var ammo_ratio = owner_agent.weapon_system.get_current_ammo() / float(owner_agent.weapon_system.current_weapon.max_ammo)
		advantage += (ammo_ratio - 0.5) * 0.2
	
	return clamp(advantage, 0.0, 1.0)

func count_nearby_allies() -> int:
	var count = 0
	for neighbor in owner_agent.neighbors:
		var ally = neighbor as FPSAgent
		if ally and ally.team_id == owner_agent.team_id:
			count += 1
	return count
