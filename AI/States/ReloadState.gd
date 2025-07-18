# Reload State
extends State
class_name ReloadState

func enter(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if not agent or not agent.weapon_system or not agent.weapon_system.current_weapon:
		# If no weapon system, can't reload, so go back
		agent.state_machine.revert_to_previous_state()
		return
	
	agent.is_reloading = true
	
	# Try to find cover while reloading
	var cover_pos = agent.find_cover()
	if cover_pos != Vector3.ZERO:
		agent.steering_manager.behaviors.clear()
		agent.steering_manager.add(ArriveBehavior.new(cover_pos))
	
	# Start the reload process on the weapon
	agent.weapon_system.current_weapon.reload()

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FPSAgent
	if not agent: return
	
	# The weapon handles the reload timer. We just wait for it to finish.
	if not agent.is_reloading:
		# Reload is complete, decide what to do next
		if agent.current_target and is_instance_valid(agent.current_target):
			agent.state_machine.change_state_by_name("combat")
		else:
			agent.state_machine.change_state_by_name("patrol")

func exit(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if agent:
		# Ensure this flag is reset when leaving the state
		agent.is_reloading = false
