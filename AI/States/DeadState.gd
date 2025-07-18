# Dead State
extends State
class_name DeadState

func enter(owner: GameEntity) -> void:
	var agent = owner as FPSAgent
	if agent:
		agent.active = false
		agent.velocity = Vector3.ZERO
		agent.steering_manager.behaviors.clear()
		
		# Make the agent non-collidable
		var collision_shape = agent.get_node_or_null("CollisionShape3D")
		if collision_shape:
			collision_shape.disabled = true
			
		# Hide the mesh or trigger a ragdoll/death animation
		var mesh = agent.get_node_or_null("MeshInstance3D")
		if mesh:
			mesh.visible = false
		
		print(agent.name + " has entered the DeadState.")
		
func execute(owner: GameEntity, delta: float) -> void:
	# The agent remains in this state until respawned or removed.
	pass
WW
