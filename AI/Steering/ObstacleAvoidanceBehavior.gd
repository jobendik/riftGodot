# Obstacle Avoidance Behavior
extends SteeringBehavior
class_name ObstacleAvoidanceBehavior

var detection_box_length: float = 5.0
var obstacles: Array[Node3D] = []

func calculate(delta: float) -> Vector3:
	if not is_instance_valid(vehicle): return Vector3.ZERO
	# This is a simplified implementation. A more robust solution would use
	# raycasts or shapecasts to detect obstacles in front of the agent.
	# The logic from the original file is complex and depends on a specific setup.
	# A raycast-based approach is more common in Godot.

	var space_state = vehicle.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = vehicle.global_position
	query.to = vehicle.global_position + vehicle.heading * detection_box_length
	query.collision_mask = 1 # World geometry layer

	var result = space_state.intersect_ray(query)
	if result:
		# Obstacle detected, calculate a force to steer away from the normal
		var avoidance_force = result.normal.slide(vehicle.heading).normalized()
		return avoidance_force * vehicle.max_force

	return Vector3.ZERO
