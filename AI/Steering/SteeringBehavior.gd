# Base Steering Behavior
extends RefCounted
class_name SteeringBehavior

var vehicle: Vehicle
var active: bool = true
var weight: float = 1.0

func calculate(delta: float) -> Vector3:
	return Vector3.ZERO
