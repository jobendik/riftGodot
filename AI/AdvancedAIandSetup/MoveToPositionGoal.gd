# Move To Position Goal
extends Goal
class_name MoveToPositionGoal

var target_position: Vector3
var arrival_distance: float = 2.0

func _init(entity: GameEntity, position: Vector3):
	owner = entity
	target_position = position

func activate() -> void:
	status = Status.ACTIVE
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.set_movement_target(target_position)

func process(delta: float) -> Status:
	if is_inactive():
		activate()
	
	var agent = owner as FullyIntegratedFPSAgent
	if not agent:
		status = Status.FAILED
		return status
	
	var distance = agent.global_position.distance_to(target_position)
	
	if distance <= arrival_distance:
		status = Status.COMPLETED
	elif agent.is_navigation_finished and distance > arrival_distance * 2:
		# Couldn't reach position, try again or fail
		agent.set_movement_target(target_position)
		if distance > 50.0:  # Too far, give up
			status = Status.FAILED
	
	return status
