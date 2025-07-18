# Custom State - Flanking Behavior
extends State
class_name FlankingState

var flank_target: GameEntity
var flank_position: Vector3

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not is_instance_valid(agent.current_target):
		if agent:
			agent.state_machine.revert_to_previous_state()
		return
	
	flank_target = agent.current_target
	
	# Calculate a flanking position to the side of the target
	var to_target = flank_target.global_position - agent.global_position
	var right = to_target.cross(Vector3.UP).normalized()
	
	# Choose a random side to flank
	var flank_side = 1 if randf() > 0.5 else -1
	flank_position = flank_target.global_position + right * flank_side * 15.0
	
	# Use NavigationAgent3D for movement instead of steering manager
	agent.set_movement_target(flank_position)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		return
	
	# If the target is lost or dead, stop flanking
	if not is_instance_valid(flank_target) or not flank_target.active:
		agent.state_machine.change_state_by_name("patrol")
		return
		
	# Once the flanking position is reached, switch back to combat
	if agent.global_position.distance_squared_to(flank_position) < 9.0: # 3 meter radius
		agent.state_machine.change_state_by_name("combat")
