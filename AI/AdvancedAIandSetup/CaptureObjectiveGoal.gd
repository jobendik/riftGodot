# Custom Goal - Capture Objective
extends CompositeGoal
class_name CaptureObjectiveGoal

var objective_position: Vector3
var capture_radius_sq: float = 25.0 # 5 meters squared
var capture_time: float = 0.0
var required_capture_time: float = 10.0

func _init(entity: GameEntity, obj_pos: Vector3):
	owner = entity
	objective_position = obj_pos

func activate() -> void:
	status = Status.ACTIVE
	remove_all_subgoals()
	# The first step is to move to the objective
	add_subgoal(MoveToPositionGoal.new(owner, objective_position))

func process(delta: float) -> Status:
	activate_if_inactive()
	
	var agent = owner as FPSAgent
	if not agent:
		status = Status.FAILED
		return status
	
	# Process subgoals (i.e., move to the objective)
	var subgoal_status = process_subgoals(delta)
	if subgoal_status == Status.FAILED:
		status = Status.FAILED
		return status

	# If we are at the objective, start capturing
	if agent.global_position.distance_squared_to(objective_position) < capture_radius_sq:
		capture_time += delta
		if capture_time >= required_capture_time:
			status = Status.COMPLETED
	else:
		# If the agent moves away, reset the capture time
		capture_time = 0
	
	return status
