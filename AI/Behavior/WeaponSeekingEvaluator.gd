extends GoalEvaluator
class_name WeaponSeekingEvaluator

func calculate_desirability(owner: GameEntity) -> float:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not agent.weapon_system:
		return 0.0
	
	var desirability = 0.0
	
	# Higher priority if we have no weapons or only basic weapons
	var weapon_count = agent.weapon_system.get_weapon_count()
	if weapon_count == 0:
		desirability = 0.95  # Extremely high priority
	elif weapon_count == 1:
		desirability = 0.7   # High priority to get backup weapon
	else:
		desirability = 0.3   # Lower priority if we have multiple weapons
	
	# Increase if we're low on ammo
	if agent.weapon_system.get_current_ammo() <= 0:
		desirability += 0.4
	elif agent.weapon_system.get_current_ammo() < 10:
		desirability += 0.2
	
	# Increase if we're low on reserve ammo
	if agent.weapon_system.get_reserve_ammo() <= 0:
		desirability += 0.3
	elif agent.weapon_system.get_reserve_ammo() < 30:
		desirability += 0.15
	
	# Decrease if we're currently in combat
	if agent.current_target:
		desirability *= 0.5
	
	# Decrease if we're low on health (health is more important)
	if agent.health < agent.max_health * 0.5:
		desirability *= 0.6
	
	return clamp(desirability * characterization_bias, 0.0, 1.0)

func set_goal(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	# Look for nearby weapons and ammo
	var nearest_pickup = _find_nearest_weapon_pickup(agent)
	
	if nearest_pickup:
		# Set the pickup as our target and switch to pickup state
		agent.set_meta("target_pickup", nearest_pickup)
		agent.state_machine.change_state_by_name("pickup_weapon")
	else:
		# No pickups found, patrol to look for them
		agent.state_machine.change_state_by_name("patrol")

func _find_nearest_weapon_pickup(agent: FullyIntegratedFPSAgent) -> Node:
	var pickup_groups = ["weapon_pickups", "ammo_pickups"]
	var nearest_pickup = null
	var nearest_distance = INF
	
	for group_name in pickup_groups:
		var pickups = agent.get_tree().get_nodes_in_group(group_name)
		
		for pickup in pickups:
			if not pickup.has_method("Get_Position"):
				continue
				
			var pickup_pos = pickup.Get_Position()
			var distance = agent.global_position.distance_to(pickup_pos)
			
			# Only consider pickups within reasonable range
			if distance < 50.0 and distance < nearest_distance:
				# Check if we actually want this pickup
				if _should_pickup_item(agent, pickup):
					nearest_distance = distance
					nearest_pickup = pickup
	
	return nearest_pickup

func _should_pickup_item(agent: FullyIntegratedFPSAgent, pickup: Node) -> bool:
	# Check if pickup is ready
	if pickup.has_method("Pick_Up_Ready") and not pickup.Pick_Up_Ready():
		return false
	
	# For weapon pickups
	if pickup.has_method("Get_Weapon"):
		var weapon_resource = pickup.Get_Weapon()
		if weapon_resource and not agent.weapon_system.has_weapon(weapon_resource.weapon_name):
			return true
	
	# For ammo pickups
	if pickup.has_method("Get_Ammo_Type"):
		var ammo_type = pickup.Get_Ammo_Type()
		# Check if we have a weapon that uses this ammo and need it
		for slot in agent.weapon_system.get_weapon_slots():
			if slot.weapon and slot.weapon.weapon_name == ammo_type:
				if slot.reserve_ammo < slot.weapon.max_ammo * 0.8:
					return true
	
	return false
