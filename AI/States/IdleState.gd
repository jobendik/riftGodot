# Idle State - Basic idle behavior for AI agents
extends State
class_name IdleState

var idle_timer: float = 0.0
var max_idle_time: float = 5.0
var look_around_timer: float = 0.0
var look_around_interval: float = 2.0

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	idle_timer = 0.0
	look_around_timer = 0.0
	max_idle_time = randf_range(3.0, 8.0)  # Random idle duration
	
	# Stop movement
	agent.navigation_agent.target_position = agent.global_position
	agent.velocity = Vector3.ZERO
	
	# Set relaxed posture
	agent.set_sprinting(false)
	agent.set_crouching(false)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	idle_timer += delta
	look_around_timer += delta
	
	# Check for enemies
	if agent.vision_system and not agent.vision_system.visible_entities.is_empty():
		for entity in agent.vision_system.visible_entities:
			var enemy = entity as FullyIntegratedFPSAgent
			if enemy and enemy.team_id != agent.team_id:
				agent.current_target = enemy
				agent.target_acquired.emit(enemy)
				agent.state_machine.change_state_by_name("combat")
				return
	
	# Look around occasionally (simulate alertness)
	if look_around_timer >= look_around_interval:
		look_around_timer = 0.0
		_look_around(agent)
	
	# Transition to patrol after idle time
	if idle_timer >= max_idle_time:
		agent.state_machine.change_state_by_name("patrol")
		return
	
	# Random chance to switch to patrol early
	if randf() < delta * 0.1:  # 10% chance per second
		agent.state_machine.change_state_by_name("patrol")

func _look_around(agent: FullyIntegratedFPSAgent):
	# Simulate looking around by briefly changing facing direction
	# This is mostly for immersion and doesn't affect vision system
	var look_directions = [
		Vector3(1, 0, 0),   # Right
		Vector3(-1, 0, 0),  # Left
		Vector3(0, 0, 1),   # Forward
		Vector3(0, 0, -1),  # Back
		Vector3(1, 0, 1).normalized(),   # Forward-right
		Vector3(-1, 0, 1).normalized()   # Forward-left
	]
	
	var look_direction = look_directions.pick_random()
	var look_target = agent.global_position + look_direction * 10.0
	
	# Create subtle look-at behavior
	var tween = agent.create_tween()
	tween.tween_method(_rotate_towards, agent.global_rotation, look_target, 0.5)

func _rotate_towards(agent_rotation: Vector3, target_pos: Vector3):
	# This would be used to smoothly rotate the agent to look at target
	# Implementation depends on your specific agent setup
	pass

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		# Reset any idle-specific settings
		look_around_timer = 0.0
		idle_timer = 0.0
