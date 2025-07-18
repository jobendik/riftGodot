extends CompositeGoal
class_name ThinkGoal

var evaluators: Array[GoalEvaluator] = []

func _init(entity: GameEntity):
	owner = entity

func add_evaluator(evaluator: GoalEvaluator) -> void:
	evaluators.append(evaluator)

func activate() -> void:
	status = Status.ACTIVE
	arbitrate()

func process(delta: float) -> Status:
	activate_if_inactive()
	
	var subgoal_status = process_subgoals(delta)
	
	if subgoal_status == Status.COMPLETED and subgoals.is_empty():
		status = Status.COMPLETED
	elif subgoal_status == Status.FAILED:
		status = Status.FAILED
	
	return status

func arbitrate() -> void:
	var best_evaluator: GoalEvaluator = null
	var best_score = 0.0
	
	for evaluator in evaluators:
		var score = evaluator.calculate_desirability(owner)
		if score > best_score:
			best_score = score
			best_evaluator = evaluator
	
	if best_evaluator and best_score > 0.3:
		best_evaluator.set_goal(owner)
