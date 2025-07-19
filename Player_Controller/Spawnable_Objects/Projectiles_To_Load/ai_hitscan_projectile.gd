extends Projectile
class_name AIProjectile

# Override the Camera_Ray_Cast to work for AI agents
func Camera_Ray_Cast(_spread: Vector2 = Vector2.ZERO, _range: float = 1000):
	# For AI, we need to raycast from the bullet point to the target
	# Start the ray slightly forward to avoid self-collision
	var Ray_Origin = global_position + (-global_transform.basis.z * 0.5)
	
	# The projectile is already rotated to face the target, so forward is -Z
	var forward = -global_transform.basis.z
	
	# Add spread - convert from screen space to world space
	var spread_world = Vector3.ZERO
	if _spread.length() > 0:
		# Create a random spread in the projectile's local space
		var right = global_transform.basis.x
		var up = global_transform.basis.y
		spread_world = (right * _spread.x + up * _spread.y) * 0.001  # Very small spread for AI
	
	# Calculate the ray end point
	var Ray_End = Ray_Origin + (forward + spread_world).normalized() * _range
	
	# Create ray query
	var New_Intersection: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	New_Intersection.set_collision_mask(0b11111111)  # Hit everything for debugging
	New_Intersection.set_hit_from_inside(false)
	New_Intersection.set_hit_back_faces(false)
	
	# Exclude the shooter from the ray - get the RID properly
	var shooter = get_meta("shooter", null)
	if shooter and shooter is CollisionObject3D:
		New_Intersection.exclude = [shooter.get_rid()]
		print("DEBUG: Excluding shooter: ", shooter.name)
	
	# Debug ray visualization
	print("DEBUG: AI Raycast from ", Ray_Origin, " to ", Ray_End)
	print("DEBUG: Direction: ", forward, " Spread: ", spread_world)
	
	# Perform the raycast
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var hit_name = "Unknown"
		if Intersection.collider is Node:
			hit_name = Intersection.collider.name
		print("DEBUG: AI Raycast hit ", hit_name, " at ", Intersection.position)
		print("DEBUG: Hit object is in Target group: ", Intersection.collider.is_in_group("Target"))
		var Collision = [Intersection.collider, Intersection.position, Intersection.normal]
		return Collision
	else:
		print("DEBUG: AI Raycast missed - no collision detected")
		return [null, Ray_End, null]

# Override Hit_Scan_damage to ensure shooter is passed correctly
func Hit_Scan_damage(Collider, Direction, Position, _damage):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Hit_Successfull.emit()
		
		# Get the shooter from metadata
		var shooter = get_meta("shooter", null)
		
		# Debug print to verify shooter is set
		if shooter:
			var shooter_name = "Unknown shooter"
			if shooter is Node:
				shooter_name = shooter.name
			print("DEBUG: AI Projectile hit by ", shooter_name)
		else:
			print("DEBUG: AI Projectile has no shooter metadata!")
		
		# Call Hit_Successful with attacker information
		if shooter:
			Collider.Hit_Successful(_damage, Direction, Position, shooter)
		else:
			Collider.Hit_Successful(_damage, Direction, Position)
