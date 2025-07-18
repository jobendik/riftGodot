# Composite Goal - Can have subgoals
extends Goal
class_name CompositeGoal

var subgoals: Array[Goal] = []

func add_subgoal(goal: Goal) -> void:
	goal.owner = owner
	subgoals.push_front(goal)

func remove_all_subgoals() -> void:
	for goal in subgoals:
		goal.terminate()
	subgoals.clear()

func process(delta: float) -> Status:
	activate_if_inactive()
	
	var subgoal_status = process_subgoals(delta)
	
	if subgoal_status == Status.COMPLETED and subgoals.is_empty():
		status = Status.COMPLETED
	elif subgoal_status == Status.FAILED:
		status = Status.FAILED
	
	return status

func process_subgoals(delta: float) -> Status:
	while not subgoals.is_empty():
		var current_goal = subgoals[0]
		
		if current_goal.is_inactive():
			current_goal.activate()
		
		var goal_status = current_goal.process(delta)
		
		if goal_status == Status.COMPLETED:
			current_goal.terminate()
			subgoals.pop_front()
		
		if goal_status != Status.COMPLETED:
			return goal_status
	
	return Status.COMPLETED

func activate_if_inactive() -> void:
	if is_inactive():
		activate()
