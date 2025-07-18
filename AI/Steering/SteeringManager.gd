# Steering Manager - Combines multiple steering behaviors
extends RefCounted
class_name SteeringManager

var vehicle: Vehicle
var behaviors: Array[SteeringBehavior] = []
var steering_force: Vector3 = Vector3.ZERO

func _init(v: Vehicle):
	vehicle = v

func add(behavior: SteeringBehavior) -> void:
	behavior.vehicle = vehicle
	behaviors.append(behavior)

func remove(behavior: SteeringBehavior) -> void:
	behaviors.erase(behavior)

func calculate(delta: float) -> Vector3:
	steering_force = Vector3.ZERO
	
	for behavior in behaviors:
		if behavior.active:
			var force = behavior.calculate(delta) * behavior.weight
			
			# Accumulate force up to max force
			if not _accumulate_force(force):
				break
	
	return steering_force

func _accumulate_force(force_to_add: Vector3) -> bool:
	var magnitude_so_far = steering_force.length()
	var magnitude_remaining = vehicle.max_force - magnitude_so_far
	
	if magnitude_remaining <= 0:
		return false
	
	var magnitude_to_add = force_to_add.length()
	
	if magnitude_to_add > magnitude_remaining:
		steering_force += force_to_add.normalized() * magnitude_remaining
		return false
	else:
		steering_force += force_to_add
		return true
