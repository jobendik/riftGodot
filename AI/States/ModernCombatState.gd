# Modern Combat State - Updated for unified weapon system
extends State
class_name ModernCombatState

var engage_distance: float = 30.0
var preferred_distance: float = 15.0
var time_in_combat: float = 0.0
var last_shot_time: float = 0.0
var strafe_direction: int = 1
var strafe_timer: float = 0.0
var combat_movement_timer: float = 0.0
var movement_update_interval: float = 0.3

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	time_in_combat = 0.0
	last_shot_time = agent.reaction_time
	strafe_direction = 1 if randf() > 0.5 else -1
	strafe_timer = randf_range(1.0, 3.0)
	combat_movement_timer = 0.0
	
	# Set aggressive movement
	agent.set_sprinting(agent.aggression > 0.6)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not is_instance_valid(agent.current_target):
		agent.current_target = null
		agent.state_machine.change_state_by_name("patrol")
		return
	
	time_in_combat += delta
	last_shot_time += delta
	combat_movement_timer += delta
	
	var target_pos = agent.current_target.global_position
	
	# Update memory
	if agent.memory_system:
		var record = agent.memory_system.get_record(agent.current_target)
		if record:
			record.last_sensed_position = target_pos
			record.time_last_sensed = Time.get_ticks_msec() / 1000.0
	
	# Combat movement and shooting
	_perform_combat_movement(agent, delta)
	_perform_shooting(agent)
	
	# Check for state transitions
	if agent.weapon_system.needs_reload():
		agent.state_machine.change_state_by_name("reload")
		return
		
	if agent.health < agent.max_health * 0.4 and randf() < delta * 0.5:
		agent.state_machine.change_state_by_name("seek_cover")
		return
	
	# Check if we should flank
	if time_in_combat > 5.0 and agent.risk_tolerance > 0.6 and randf() < delta * 0.3:
		agent.state_machine.change_state_by_name("flanking")
		return

func _perform_combat_movement(agent: FullyIntegratedFPSAgent, delta: float):
	if combat_movement_timer < movement_update_interval:
		return
	
	combat_movement_timer = 0.0
	
	var distance = agent.global_position.distance_to(agent.current_target.global_position)
	var target_position = Vector3.ZERO
	
	# Auto-switch weapon based on distance
	agent.weapon_system.auto_switch_weapon(distance)
	
	# Determine movement strategy
	if distance > preferred_distance * 1.5:
		target_position = _get_approach_position(agent)
	elif distance < preferred_distance * 0.7:
		target_position = _get_retreat_position(agent)
	else:
		target_position = _get_strafe_position(agent, delta)
	
	if target_position != Vector3.ZERO:
		agent.set_movement_target(target_position)

func _get_approach_position(agent: FullyIntegratedFPSAgent) -> Vector3:
	var to_target = agent.current_target.global_position - agent.global_position
	var approach_distance = preferred_distance * 1.2
	
	var side_offset = Vector3(to_target.z, 0, -to_target.x).normalized() * 5.0
	var approach_pos = agent.current_target.global_position - to_target.normalized() * approach_distance
	
	return approach_pos + side_offset

func _get_retreat_position(agent: FullyIntegratedFPSAgent) -> Vector3:
	var from_target = agent.global_position - agent.current_target.global_position
	var retreat_distance = preferred_distance * 1.1
	
	return agent.current_target.global_position + from_target.normalized() * retreat_distance

func _get_strafe_position(agent: FullyIntegratedFPSAgent, delta: float) -> Vector3:
	strafe_timer -= delta
	if strafe_timer <= 0:
		strafe_direction *= -1
		strafe_timer = randf_range(1.5, 4.0)
	
	var to_target = agent.current_target.global_position - agent.global_position
	var right = to_target.cross(Vector3.UP).normalized()
	var strafe_distance = 8.0 + (agent.aggression * 5.0)
	
	return agent.global_position + right * strafe_direction * strafe_distance

func _perform_shooting(agent: FullyIntegratedFPSAgent):
	if not agent.weapon_system.can_fire():
		return
	
	if last_shot_time > agent.reaction_time:
		if agent.vision_system and agent.vision_system.can_see(agent.current_target):
			# Predict target position
			var predicted_pos = _predict_target_position(agent)
			
			# Fire using unified weapon system
			if agent.weapon_system.fire_at(predicted_pos):
				last_shot_time = 0.0

func _predict_target_position(agent: FullyIntegratedFPSAgent) -> Vector3:
	var target = agent.current_target
	var target_pos = target.global_position
	
	# Simple prediction based on target velocity
	if target.has_method("get_velocity"):
		var target_velocity = target.get_velocity()
		var distance = agent.global_position.distance_to(target_pos)
		var time_to_hit = distance / 50.0  # Assume bullet speed
		target_pos += target_velocity * time_to_hit
	
	return target_pos

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.set_sprinting(false)
