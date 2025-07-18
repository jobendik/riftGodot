# Goal-Driven Agent Design
extends RefCounted
class_name Goal

enum Status {
	INACTIVE,
	ACTIVE,
	COMPLETED,
	FAILED
}

var status: Status = Status.INACTIVE
var owner: GameEntity

func activate() -> void:
	status = Status.ACTIVE

func process(delta: float) -> Status:
	return status

func terminate() -> void:
	status = Status.INACTIVE

func add_subgoal(goal: Goal) -> void:
	# Only CompositeGoal should implement this
	pass

func is_active() -> bool:
	return status == Status.ACTIVE

func is_inactive() -> bool:
	return status == Status.INACTIVE

func is_completed() -> bool:
	return status == Status.COMPLETED

func has_failed() -> bool:
	return status == Status.FAILED
