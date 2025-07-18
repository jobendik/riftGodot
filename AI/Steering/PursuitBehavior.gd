# Pursuit Behavior
extends SteeringBehavior
class_name PursuitBehavior

var evader: Vehicle

func _init(target_vehicle: Vehicle = null):
	evader = target_vehicle

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle) or not is_instance_valid(evader):
		return Vector3.ZERO
	
	var to_evader = evader.global_position - vehicle.global_position
	var relative_heading = vehicle.heading.dot(evader.heading)
	
	# If evader is ahead and facing us, seek directly
	if to_evader.dot(vehicle.heading) > 0 and relative_heading < -0.95:
		var seek = SeekBehavior.new(evader.global_position)
		seek.vehicle = vehicle
		return seek.calculate(delta)
	
	# Predict where the evader will be
	var look_ahead_time = to_evader.length() / (vehicle.max_speed + evader.velocity.length())
	var predicted_pos = evader.global_position + evader.velocity * look_ahead_time
	
	var seek_predicted = SeekBehavior.new(predicted_pos)
	seek_predicted.vehicle = vehicle
	return seek_predicted.calculate(delta)
