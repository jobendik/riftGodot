# Modern Dead State - Updated for FullyIntegratedFPSAgent
extends State
class_name ModernDeadState

var death_timer: float = 0.0
var corpse_duration: float = 10.0  # How long the corpse remains
var death_effects_played: bool = false

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	death_timer = 0.0
	death_effects_played = false
	
	# Stop all movement and AI processing
	agent.velocity = Vector3.ZERO
	agent.current_target = null
	agent.stress_level = 0.0
	agent.is_reloading = false
	
	# Disable navigation
	if agent.navigation_agent:
		agent.navigation_agent.avoidance_enabled = false
		agent.navigation_agent.target_position = agent.global_position
	
	# Disable collision for other agents
	agent.collision_layer = 0
	agent.collision_mask = 1  # Only collide with world
	
	# Stop all systems
	if agent.vision_system:
		agent.vision_system.visible_entities.clear()
	
	if agent.weapon_system:
		# Drop current weapon if possible
		var dropped_weapon = agent.weapon_system.drop_current_weapon()
		if dropped_weapon:
			agent.get_tree().current_scene.add_child(dropped_weapon)
			dropped_weapon.global_position = agent.global_position + Vector3(0, 1, 0)
			dropped_weapon.apply_central_impulse(Vector3(randf_range(-3, 3), 2, randf_range(-3, 3)))
	
	# Visual effects
	_play_death_effects(agent)
	
	# Notify learning system about death
	if agent.learning_system:
		agent.learning_system.learn_from_combat(agent.current_target, "defeat")
	
	# Notify morale system
	if agent.morale_system:
		agent.morale_system.morale = 0.0
		agent.morale_system.fear = 1.0
	
	# Notify team members
	_notify_team_of_death(agent)
	
	print(agent.name + " has died and entered DeadState")

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	death_timer += delta
	
	# Play death effects if not already done
	if not death_effects_played:
		_play_death_effects(agent)
		death_effects_played = true
	
	# The agent remains in this state until respawned or removed
	# Game manager handles respawning
	
	# Optional: Remove corpse after certain time
	if death_timer >= corpse_duration:
		_remove_corpse(agent)

func _play_death_effects(agent: FullyIntegratedFPSAgent):
	# Make death sound
	if agent.sound_emitter:
		agent.sound_emitter.emit_voice("death")
	
	# Visual death effects
	var mesh = agent.get_node_or_null("MeshInstance3D")
	if mesh:
		# Create death animation/effect
		var tween = agent.create_tween()
		tween.tween_property(mesh, "modulate", Color(0.5, 0.5, 0.5, 0.7), 1.0)
		tween.tween_property(mesh, "position", mesh.position + Vector3(0, -0.5, 0), 2.0)
	
	# Create death particle effect (if you have particle systems)
	_create_death_particles(agent)

func _create_death_particles(agent: FullyIntegratedFPSAgent):
	# Create simple death effect
	# You can replace this with more sophisticated particle systems
	var death_marker = MeshInstance3D.new()
	death_marker.name = "DeathMarker"
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	death_marker.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.flags_transparent = true
	material.albedo_color.a = 0.3
	death_marker.material_override = material
	
	agent.add_child(death_marker)
	death_marker.position = Vector3(0, 0.5, 0)
	
	# Fade out death marker
	var tween = agent.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 5.0)
	tween.tween_callback(death_marker.queue_free)

func _notify_team_of_death(agent: FullyIntegratedFPSAgent):
	# Notify team members about death for morale effects
	if agent.team_id > 0:
		var death_msg = TeamCommunication.TeamMessage.new(
			"teammate_died",
			{
				"dead_agent": agent,
				"position": agent.global_position,
				"cause": "combat"
			},
			agent,
			TeamCommunication.MessagePriority.HIGH
		)
		TeamCommunication.broadcast(agent.team_id, death_msg)
	
	# Notify nearby agents directly
	if agent.entity_manager:
		var nearby_agents = agent.entity_manager.get_neighbors(agent, 30.0)
		for nearby_agent in nearby_agents:
			if nearby_agent.has_method("on_teammate_death") and nearby_agent.team_id == agent.team_id:
				nearby_agent.on_teammate_death(agent)

func _remove_corpse(agent: FullyIntegratedFPSAgent):
	# Optional: Remove the corpse after duration
	# This depends on your game's needs
	var mesh = agent.get_node_or_null("MeshInstance3D")
	if mesh:
		var tween = agent.create_tween()
		tween.tween_property(mesh, "modulate:a", 0.0, 2.0)
		tween.tween_callback(func(): mesh.visible = false)

func exit(owner: GameEntity) -> void:
	# This state is typically only exited when the agent is respawned
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	# Reset agent for respawn
	agent.health = agent.max_health
	agent.stress_level = 0.0
	agent.is_reloading = false
	
	# Re-enable collision
	agent.collision_layer = 2  # Agent layer
	agent.collision_mask = 3   # World + Agent layers
	
	# Re-enable navigation
	if agent.navigation_agent:
		agent.navigation_agent.avoidance_enabled = true
	
	# Reset visual effects
	var mesh = agent.get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.modulate = Color.WHITE
		mesh.visible = true
		mesh.position = Vector3.ZERO
	
	# Reset health system
	if agent.health_system:
		agent.health_system.current_health = agent.health_system.max_health
	
	# Reset morale system
	if agent.morale_system:
		agent.morale_system.morale = 0.7
		agent.morale_system.fear = 0.1
		agent.morale_system.confidence = 0.5
	
	print(agent.name + " has been respawned and exited DeadState")
