# Combat State
extends State
class_name CombatState

var engage_distance: float = 30.0
var preferred_distance: float = 15.0
var time_in_combat: float = 0.0
var last_shot_time: float = 0.0
var strafe_direction: int = 1
var strafe_timer: float = 0.0

func enter(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if not agent: return
	
	time_in_combat = 0.0
	last_shot_time = agent.reaction_time # Initial delay before first shot
	strafe_direction = 1 if randf() > 0.5 else -1
	strafe_timer = randf_range(1.0, 3.0)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FPSAgent
	if not agent or not is_instance_valid(agent.current_target) or not agent.current_target.active:
		agent.current_target = null
		agent.state_machine.change_state_by_name("patrol")
		return
	
	time_in_combat += delta
	last_shot_time += delta
	
	var target_pos = agent.current_target.global_position
	
	# Update memory of last known position
	if agent.memory_system:
		var record = agent.memory_system.get_record(agent.current_target)
		if record:
			record.last_sensed_position = target_pos
			record.time_last_sensed = Time.get_ticks_msec() / 1000.0
	
	# Perform combat movement and shooting
	_perform_combat_movement(agent, delta)
	_perform_shooting(agent)
	
	# Check for state transitions
	if agent.weapon_system and agent.weapon_system.get_current_ammo() <= 0:
		agent.state_machine.change_state_by_name("reload")
		return
		
	if agent.health < agent.max_health * 0.4 and randf() < delta * 0.5:
		agent.state_machine.change_state_by_name("seek_cover")
		return

func _perform_combat_movement(agent: FPSAgent, delta: float):
	agent.steering_manager.behaviors.clear()
	var distance = agent.global_position.distance_to(agent.current_target.global_position)
	
	# Maintain preferred distance
	if distance > preferred_distance * 1.5:
		agent.steering_manager.add(PursuitBehavior.new(agent.current_target as Vehicle))
	elif distance < preferred_distance * 0.7:
		agent.steering_manager.add(FleeBehavior.new(agent.current_target.global_position))
	else:
		# Strafe left and right
		strafe_timer -= delta
		if strafe_timer <= 0:
			strafe_direction *= -1
			strafe_timer = randf_range(1.5, 4.0)
		
		var to_target = agent.current_target.global_position - agent.global_position
		var right = to_target.cross(Vector3.UP).normalized()
		var strafe_target = agent.global_position + right * strafe_direction * 5.0
		agent.steering_manager.add(SeekBehavior.new(strafe_target))

func _perform_shooting(agent: FPSAgent):
	if agent.weapon_system and agent.weapon_system.can_fire():
		if last_shot_time > agent.reaction_time:
			if agent.vision_system and agent.vision_system.can_see(agent.current_target):
				agent.weapon_system.fire_at(agent.current_target.global_position)
				last_shot_time = 0.0
