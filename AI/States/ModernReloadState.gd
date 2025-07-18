# Modern Reload State - Uses unified weapon system
extends State
class_name ModernReloadState

var reload_started: bool = false

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not agent.weapon_system:
		agent.state_machine.revert_to_previous_state()
		return
	
	reload_started = false
	
	# Try to find cover while reloading
	var cover_pos = agent.find_cover()
	if cover_pos != Vector3.ZERO:
		agent.set_movement_target(cover_pos)
		agent.set_crouching(true)
	
	# Start reload using unified weapon system
	if agent.weapon_system.can_fire() == false and agent.weapon_system.needs_reload():
		agent.weapon_system.reload()
		reload_started = true
	else:
		# No reload needed, go back to previous state
		agent.state_machine.revert_to_previous_state()

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	# Check if reload is complete
	if not agent.is_reloading and reload_started:
		# Reload complete, decide what to do next
		if agent.current_target and is_instance_valid(agent.current_target):
			agent.state_machine.change_state_by_name("combat")
		else:
			agent.state_machine.change_state_by_name("patrol")
		return
	
	# If under attack during reload, consider seeking cover
	if agent.current_target and agent.stress_level > 0.7:
		if agent.global_position.distance_to(agent.current_target.global_position) < 10.0:
			agent.state_machine.change_state_by_name("seek_cover")
			return

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.set_crouching(false)
