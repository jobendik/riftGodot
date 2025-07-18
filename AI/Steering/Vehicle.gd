# Vehicle/Agent Movement Controller
extends GameEntity
class_name Vehicle

@export var mass: float = 1.0
@export var max_speed: float = 10.0
@export var max_force: float = 100.0
@export var max_turn_rate: float = PI

var velocity: Vector3 = Vector3.ZERO
var heading: Vector3 = Vector3.FORWARD
var side: Vector3 = Vector3.RIGHT
var steering_manager: SteeringManager

func _ready():
	super._ready()
	steering_manager = SteeringManager.new(self)

func update(delta: float) -> void:
	# This update is often called by a manager or the physics process
	# Calculate combined steering force
	var steering_force = steering_manager.calculate(delta)
	
	# Acceleration = Force / Mass
	var acceleration = steering_force / mass
	
	# Update velocity
	velocity += acceleration * delta
	
	# Truncate to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	# Update position
	global_position += velocity * delta
	
	# Update orientation if moving
	if velocity.length_squared() > 0.001:
		heading = velocity.normalized()
		side = heading.cross(Vector3.UP).normalized()
		look_at(global_position + heading, Vector3.UP)
