# Flee Behavior
extends SteeringBehavior
class_name FleeBehavior

var target: Vector3
var panic_distance: float = 10.0

func _init(target_pos: Vector3 = Vector3.ZERO):
	target = target_pos

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle): return Vector3.ZERO
	var distance = vehicle.global_position.distance_to(target)
	
	if distance > panic_distance:
		return Vector3.ZERO
	
	var desired_velocity = (vehicle.global_position - target).normalized() * vehicle.max_speed
	return desired_velocity - vehicle.velocity
