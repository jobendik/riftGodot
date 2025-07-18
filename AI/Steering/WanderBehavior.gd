# Wander Behavior
extends SteeringBehavior
class_name WanderBehavior

var wander_radius: float = 2.0
var wander_distance: float = 5.0
var wander_jitter: float = 80.0 # Increased for more erratic movement
var wander_target: Vector3

func _init():
	# Random point on circle
	var theta = randf() * TAU
	wander_target = Vector3(cos(theta), 0, sin(theta)) * wander_radius

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle): return Vector3.ZERO
	# Add random jitter
	wander_target += Vector3(
		randf_range(-1, 1) * wander_jitter * delta,
		0,
		randf_range(-1, 1) * wander_jitter * delta
	)
	
	# Project back onto circle
	wander_target = wander_target.normalized() * wander_radius
	
	# Move circle in front of vehicle
	var target_local = wander_target + Vector3.FORWARD * wander_distance
	var target_world = vehicle.global_transform * target_local
	
	return target_world - vehicle.global_position
