# Evade Behavior
extends SteeringBehavior
class_name EvadeBehavior

var pursuer: Vehicle
var threat_range: float = 100.0

func _init(target_vehicle: Vehicle = null):
	pursuer = target_vehicle

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle) or not is_instance_valid(pursuer):
		return Vector3.ZERO
	
	var to_pursuer = pursuer.global_position - vehicle.global_position
	
	if to_pursuer.length() > threat_range:
		return Vector3.ZERO
	
	var look_ahead_time = to_pursuer.length() / (vehicle.max_speed + pursuer.velocity.length())
	var predicted_pos = pursuer.global_position + pursuer.velocity * look_ahead_time
	
	var flee = FleeBehavior.new(predicted_pos)
	flee.vehicle = vehicle
	return flee.calculate(delta)
