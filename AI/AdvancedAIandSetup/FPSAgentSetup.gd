# FPS AI Agent Scene Setup Example
extends Node
class_name FPSAgentSetup

# This class is a conceptual guide. In a real project, you would create a scene
# for your agent in the Godot editor and instantiate that scene. This script
# shows how you could build an agent entirely from code.

func create_fps_agent(spawn_position: Vector3, team_id: int) -> FPSAgent:
	# Create the root node for the agent
	var agent = FPSAgent.new()
	agent.global_position = spawn_position
	agent.team_id = team_id
	
	# Add a CollisionShape3D for physics
	var collision_shape = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.5
	capsule_shape.height = 1.8
	collision_shape.shape = capsule_shape
	agent.add_child(collision_shape)
	
	# Add a visual representation
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.5
	capsule_mesh.mid_height = 1.8
	mesh_instance.mesh = capsule_mesh
	agent.add_child(mesh_instance)
	
	# Add the core AI component nodes
	agent.add_child(NavigationAgent3D.new())
	agent.add_child(VisionSystem.new())
	agent.add_child(WeaponSystem.new())
	agent.add_child(HealthSystem.new())
	
	return agent
