# Arrive Behavior
extends SteeringBehavior
class_name ArriveBehavior

var target: Vector3
var deceleration_rate: float = 3.0

func _init(target_pos: Vector3 = Vector3.ZERO):
	target = target_pos

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle): return Vector3.ZERO
	var to_target = target - vehicle.global_position
	var distance = to_target.length()
	
	if distance > 0:
		var speed = min(distance / deceleration_rate, vehicle.max_speed)
		var desired_velocity = to_target.normalized() * speed
		return desired_velocity - vehicle.velocity
	
	return Vector3.ZERO
