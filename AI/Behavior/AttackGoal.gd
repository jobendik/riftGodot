extends Goal
class_name AttackGoal

var target: FullyIntegratedFPSAgent

func _init(entity: GameEntity, target_entity: FullyIntegratedFPSAgent):
	owner = entity
	target = target_entity

func activate() -> void:
	status = Status.ACTIVE

func process(delta: float) -> Status:
	if is_inactive():
		activate()
	
	var agent = owner as FullyIntegratedFPSAgent
	if not agent or not is_instance_valid(target):
		status = Status.FAILED
		return status
	
	# Switch to combat state
	agent.state_machine.change_state_by_name("combat")
	
	if target.health <= 0:
		status = Status.COMPLETED
	
	return status
