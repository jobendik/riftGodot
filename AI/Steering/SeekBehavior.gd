# Seek Behavior
extends SteeringBehavior
class_name SeekBehavior

var target: Vector3

func _init(target_pos: Vector3 = Vector3.ZERO):
	target = target_pos

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle): return Vector3.ZERO
	var desired_velocity = (target - vehicle.global_position).normalized() * vehicle.max_speed
	return desired_velocity - vehicle.velocity
