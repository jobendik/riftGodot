# Fully Integrated AI Agent - Uses same weapon system as player
extends GameEntity
class_name FullyIntegratedFPSAgent

# Core Components (same structure as player)
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_system: VisionSystem = $VisionSystem
@onready var weapon_system: UnifiedAIWeaponSystem = $UnifiedAIWeaponSystem
@onready var health_system: HealthSystem = $HealthSystem
@onready var hearing_system: HearingSystem = $HearingSystem
@onready var sound_emitter: SoundEmitter = $SoundEmitter

# Weapon pickup detection
@onready var pickup_detector: Area3D = $PickupDetector
@onready var pickup_collision: CollisionShape3D = $PickupDetector/CollisionShape3D

# AI Systems
var state_machine: StateMachine
var think_goal: ThinkGoal
var memory_system: MemorySystem
var fuzzy_weapon_selector: WeaponSelectionFuzzy
var tactical_analyzer: TacticalAnalyzer
var learning_system: LearningSystem
var morale_system: MoraleSystem
var environmental_awareness: EnvironmentalAwareness

# Navigation and Movement
@export var movement_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
var target_update_interval: float = 0.5
var last_target_update: float = 0.0
var is_sprinting: bool = false
var is_crouching: bool = false

# Agent Properties
@export var max_health: float = 100.0
var health: float = 100.0
var armor: float = 0.0

# Behavior Parameters
@export_range(0.0, 1.0) var aggression: float = 0.7
@export_range(0.0, 1.0) var accuracy: float = 0.8
@export_range(0.0, 1.0) var reaction_time: float = 0.2
@export_range(0.0, 1.0) var team_loyalty: float = 0.9
@export_range(0.0, 1.0) var risk_tolerance: float = 0.5

# Internal State
var current_target: FullyIntegratedFPSAgent = null
var last_known_enemy_position: Vector3
var time_since_last_enemy_seen: float = 0.0
var is_reloading: bool = false
var stress_level: float = 0.0
var current_movement_state: String = "walking"

# Navigation state
var movement_target: Vector3
var is_navigation_finished: bool = true

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Note: uuid, neighbors, entity_manager, and active are inherited from GameEntity parent class

# Signals
signal on_death
signal on_damage(amount: float, attacker: FullyIntegratedFPSAgent)
signal target_acquired(target: FullyIntegratedFPSAgent)
signal target_lost(target: FullyIntegratedFPSAgent)
signal weapon_picked_up(weapon_name: String)

func _ready():
	print("DEBUG: Agent ", name, " _ready() called")
	uuid = _generate_uuid()
	print("DEBUG: Agent UUID: ", uuid)
	
	add_to_group("Target")
	
	_initialize_weapon_system()
	_initialize_navigation()
	_initialize_ai_systems()
	_setup_state_machine()
	_setup_goals()
	_setup_connections()
	_setup_pickup_detection()
	# Defer weapon loading to ensure all systems are ready
	call_deferred("_setup_initial_loadout")
	
	collision_layer = 2  # AI agents are on layer 2
	collision_mask = 3   # Collide with world (layer 1) and other agents (layer 2)
	
	# ADD THIS - Set team colors after all initialization
	_setup_team_colors()
	
	if health_system:
		health_system.health_depleted.connect(_on_health_depleted)
		health_system.health_changed.connect(func(current, max_health): health = current)
		print("DEBUG: Agent health initialized: ", health_system.current_health, "/", health_system.max_health)
	else:
		print("ERROR: No health system found!")
	
	# Debug component check
	print("DEBUG [", name, "]: Component Check:")
	print("  - NavigationAgent3D: ", navigation_agent != null)
	print("  - VisionSystem: ", vision_system != null)
	print("  - WeaponSystem: ", weapon_system != null)
	print("  - HealthSystem: ", health_system != null)
	print("  - HearingSystem: ", hearing_system != null)
	print("  - SoundEmitter: ", sound_emitter != null)
	print("  - PickupDetector: ", pickup_detector != null)
	print("  - StateMachine: ", state_machine != null)
	print("  - ThinkGoal: ", think_goal != null)
	
	print("DEBUG: Agent ", name, " fully initialized with health: ", health)
	# Add debug test at the end
	call_deferred("debug_test_systems")
	
func _generate_uuid() -> String:
	return "agent_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

# ADD THIS NEW FUNCTION
func _setup_team_colors():
	var mesh = get_node_or_null("MeshInstance3D")
	if not mesh:
		return
	
	# Create team-based material
	var team_material = StandardMaterial3D.new()
	
	match team_id:
		1:
			team_material.albedo_color = Color.GREEN  # Team 1 = Green (Friends)
		2:
			team_material.albedo_color = Color.RED    # Team 2 = Red (Enemies)
		_:
			team_material.albedo_color = Color.GRAY   # Neutral/Unknown
	
	# Apply the team material
	mesh.material_override = team_material
	print("DEBUG [", name, "]: Applied team color for team ", team_id)

func _initialize_weapon_system():
	if weapon_system:
		weapon_system.owner_agent = self
		weapon_system.weapon_switched.connect(_on_weapon_switched)
		weapon_system.ammo_changed.connect(_on_ammo_changed)
		weapon_system.weapon_fired.connect(_on_weapon_fired)
		weapon_system.reload_started.connect(_on_reload_started)
		weapon_system.reload_completed.connect(_on_reload_completed)

func _initialize_navigation():
	# Configure NavigationAgent3D for FPS AI
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_agent.target_reached.connect(_on_target_reached)
	navigation_agent.waypoint_reached.connect(_on_waypoint_reached)
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	
	# Navigation properties
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 2.0
	navigation_agent.path_max_distance = 10.0
	
	# Avoidance configuration
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.6
	navigation_agent.height = 1.8
	navigation_agent.max_speed = movement_speed
	navigation_agent.neighbor_distance = 8.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon_agents = 2.0
	navigation_agent.time_horizon_obstacles = 1.5
	
	# Avoidance layers (team-based)
	navigation_agent.avoidance_layers = 1 << team_id
	navigation_agent.avoidance_mask = 0b11111111  # Avoid all layers
	navigation_agent.avoidance_priority = 0.5

func _initialize_ai_systems():
	memory_system = MemorySystem.new()
	fuzzy_weapon_selector = WeaponSelectionFuzzy.new()
	tactical_analyzer = TacticalAnalyzer.new(self)
	learning_system = LearningSystem.new(self)
	morale_system = MoraleSystem.new(self)
	environmental_awareness = EnvironmentalAwareness.new(self)
	
	if vision_system:
		vision_system.owner_entity = self
		vision_system.memory_system = memory_system

func _setup_state_machine():
	state_machine = StateMachine.new(self)
	state_machine.add_state("idle", IdleState.new())
	state_machine.add_state("patrol", ModernPatrolState.new())
	state_machine.add_state("combat", ModernCombatState.new())
	state_machine.add_state("seek_cover", ModernSeekCoverState.new())
	state_machine.add_state("reload", ModernReloadState.new())
	state_machine.add_state("heal", ModernHealState.new())
	state_machine.add_state("flanking", FlankingState.new())
	state_machine.add_state("investigate", InvestigateState.new())
	state_machine.add_state("pickup_weapon", PickupWeaponState.new())
	state_machine.add_state("dead", ModernDeadState.new())
	state_machine.change_state_by_name("patrol")

func _setup_goals():
	think_goal = ThinkGoal.new(self)
	think_goal.add_evaluator(AttackEvaluator.new())
	think_goal.add_evaluator(ExploreEvaluator.new())
	think_goal.add_evaluator(GetHealthEvaluator.new())
	think_goal.add_evaluator(GetWeaponEvaluator.new())
	think_goal.add_evaluator(WeaponSeekingEvaluator.new())
	think_goal.add_evaluator(MapControlEvaluator.new())
	think_goal.add_evaluator(HelpTeammateEvaluator.new())

func _setup_connections():
	if hearing_system:
		hearing_system.sound_heard.connect(_on_sound_heard)
		hearing_system.owner_entity = self
	
	if vision_system:
		vision_system.owner_entity = self

func _setup_pickup_detection():
	if pickup_detector:
		pickup_detector.body_entered.connect(_on_pickup_detected)
		pickup_detector.area_entered.connect(_on_pickup_area_detected)
		
		# Set up collision shape for pickup detection
		if pickup_collision:
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = 3.0
			pickup_collision.shape = sphere_shape

func _setup_initial_loadout():
	print("DEBUG [", name, "]: Setting up initial loadout...")
	
	# Check if weapon system is ready
	if not weapon_system:
		print("ERROR [", name, "]: Weapon system is null!")
		return
		
	print("DEBUG [", name, "]: Weapon system ready: ", weapon_system != null)
	
	# Give AI agent initial weapons (use regular weapon resources)
	# Load weapon resources
	var pistol_path = "res://Player_Controller/scripts/Weapon_State_Machine/Weapon_Resources/blasterN.tres"
	var rifle_path = "res://Player_Controller/scripts/Weapon_State_Machine/Weapon_Resources/blasterI.tres"
	
	print("DEBUG [", name, "]: Loading pistol from: ", pistol_path)
	var pistol = ResourceLoader.load(pistol_path) as WeaponResource
	
	if pistol:
		print("DEBUG [", name, "]: Pistol loaded successfully: ", pistol.weapon_name)
		print("DEBUG [", name, "]: Pistol damage: ", pistol.damage)
		print("DEBUG [", name, "]: Pistol magazine: ", pistol.magazine)
		var success = weapon_system.add_weapon_from_resource(pistol, pistol.magazine, pistol.max_ammo)
		print("DEBUG [", name, "]: Pistol add success: ", success)
	else:
		print("ERROR [", name, "]: Failed to load pistol resource from: ", pistol_path)
	
	if randf() > 0.5:  # 50% chance to have rifle
		print("DEBUG [", name, "]: Loading rifle from: ", rifle_path)
		var rifle = ResourceLoader.load(rifle_path) as WeaponResource
		
		if rifle:
			print("DEBUG [", name, "]: Rifle loaded successfully: ", rifle.weapon_name)
			print("DEBUG [", name, "]: Rifle damage: ", rifle.damage)
			print("DEBUG [", name, "]: Rifle magazine: ", rifle.magazine)
			var success = weapon_system.add_weapon_from_resource(rifle, rifle.magazine, rifle.max_ammo)
			print("DEBUG [", name, "]: Rifle add success: ", success)
		else:
			print("ERROR [", name, "]: Failed to load rifle resource from: ", rifle_path)
	
	print("DEBUG [", name, "]: Weapon count after setup: ", weapon_system.get_weapon_count())
	if weapon_system.current_weapon_slot:
		print("DEBUG [", name, "]: Current weapon: ", weapon_system.current_weapon_slot.weapon.weapon_name)
		print("DEBUG [", name, "]: Current weapon can fire: ", weapon_system.can_fire())

func _physics_process(delta):
	# Don't process if navigation map isn't ready
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	
	# Update AI systems
	_update_ai_systems(delta)
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle navigation movement
	if not navigation_agent.is_navigation_finished():
		_handle_navigation_movement(delta)
	else:
		# No navigation target, let AI state handle movement
		_handle_state_movement(delta)
	
	# Apply movement
	move_and_slide()

func _update_ai_systems(delta):
	# Update enemy tracking timer
	_update_enemy_tracking(delta)
	
	# Add debug output every 2 seconds
	if fmod(Time.get_ticks_msec() / 1000.0, 2.0) < delta:
		print("DEBUG [", name, "]: State=", state_machine.current_state.get_script().get_global_name() if state_machine and state_machine.current_state else "NO_STATE")
		print("DEBUG [", name, "]: Vision System=", vision_system != null)
		print("DEBUG [", name, "]: Current Target=", current_target != null)
		print("DEBUG [", name, "]: Time since last enemy seen=", time_since_last_enemy_seen)
		if vision_system:
			print("DEBUG [", name, "]: Visible Entities=", vision_system.visible_entities.size())
			for entity in vision_system.visible_entities:
				if entity is FullyIntegratedFPSAgent:
					print("  - Sees: ", entity.name, " Team:", entity.team_id, " My Team:", team_id)
	
	if vision_system:
		vision_system.update()
	
	if state_machine:
		state_machine.update(delta)
	
	if think_goal:
		think_goal.process(delta)
	
	if learning_system and current_target:
		learning_system.adapt_strategy(current_target)
	
	if morale_system:
		morale_system.update(delta)
	
	if environmental_awareness:
		environmental_awareness.update()
	
	_update_stress_level(delta)
	_update_weapon_selection()

func _update_enemy_tracking(delta: float):
	var enemy_spotted = false
	
	# Check if we can see any enemies
	if vision_system:
		for entity in vision_system.visible_entities:
			var enemy = entity as FullyIntegratedFPSAgent
			if enemy and enemy.team_id != team_id:
				enemy_spotted = true
				time_since_last_enemy_seen = 0.0
				break
	
	# Check if we have a current target
	if current_target and is_instance_valid(current_target):
		enemy_spotted = true
		time_since_last_enemy_seen = 0.0
	
	# Update timer if no enemies seen
	if not enemy_spotted:
		time_since_last_enemy_seen += delta
	
	# Clear target if we haven't seen enemies for too long
	if time_since_last_enemy_seen > 20.0 and current_target:
		current_target = null
		target_lost.emit(current_target)

func _handle_navigation_movement(delta):
	var next_path_position = navigation_agent.get_next_path_position()
	var current_position = global_position
	
	# Calculate movement direction on XZ plane
	var direction = Vector3(
		next_path_position.x - current_position.x,
		0,
		next_path_position.z - current_position.z
	).normalized()
	
	# Apply movement speed based on current state
	var speed = _get_current_movement_speed()
	var new_velocity = direction * speed
	
	# Preserve Y velocity for gravity
	new_velocity.y = velocity.y
	
	# Use avoidance if enabled
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = new_velocity
	else:
		velocity = new_velocity

func _handle_state_movement(delta):
	pass

func _get_current_movement_speed() -> float:
	var base_speed = movement_speed
	
	if is_sprinting:
		base_speed = sprint_speed
	elif is_crouching:
		base_speed = crouch_speed
	
	# Apply stress and morale modifiers
	var stress_modifier = 1.0 + (stress_level * 0.3)
	var morale_modifier = 1.0
	
	if morale_system:
		if morale_system.is_panicking:
			morale_modifier = 1.5
		elif morale_system.morale < 0.3:
			morale_modifier = 0.8
	
	return base_speed * stress_modifier * morale_modifier

func set_movement_target(target_position: Vector3):
	movement_target = target_position
	navigation_agent.target_position = target_position
	is_navigation_finished = false

func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity

func _on_target_reached():
	is_navigation_finished = true

func _on_waypoint_reached(details: Dictionary):
	pass

func _on_navigation_finished():
	is_navigation_finished = true

func _update_stress_level(delta: float):
	if current_target:
		stress_level = min(stress_level + delta * 0.5, 1.0)
	elif health < max_health * 0.3:
		stress_level = min(stress_level + delta * 0.3, 1.0)
	else:
		stress_level = max(stress_level - delta * 0.2, 0.0)

func _update_weapon_selection():
	if not current_target or not weapon_system:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	
	# Auto-switch to best weapon for current situation
	if randf() < 0.1:  # 10% chance per frame to consider switching
		weapon_system.auto_switch_weapon(distance)

func take_damage(amount: float, attacker: FullyIntegratedFPSAgent = null):
	if not health_system or health <= 0:
		return
	
	# Check for friendly fire
	if attacker and attacker.team_id == team_id:
		# Same team - check if friendly fire is enabled
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager and not game_manager.enable_friendly_fire:
			print("DEBUG [", name, "]: Blocked friendly fire from ", attacker.name)
			return
	
	print("DEBUG [", name, "]: TAKING DAMAGE ", amount, " from ", attacker.name if attacker else "unknown")
	
	health_system.take_damage(amount)
	on_damage.emit(amount, attacker)
	
	if learning_system and attacker:
		learning_system.learn_from_damage(attacker, amount)
	
	if morale_system and attacker:
		if attacker.team_id != team_id:
			morale_system.fear = min(morale_system.fear + 0.2, 1.0)
	
	if health > 0:
		stress_level = min(stress_level + 0.3, 1.0)
		if attacker and attacker.team_id != team_id and not current_target:
			current_target = attacker
			target_acquired.emit(attacker)
			print("DEBUG [", name, "]: ACQUIRED TARGET ", attacker.name, " - SWITCHING TO COMBAT")
			state_machine.change_state_by_name("combat")

func _on_health_depleted():
	state_machine.change_state_by_name("dead")
	on_death.emit()

func _on_sound_heard(event: HearingSystem.SoundEvent):
	match event.type:
		"gunshot":
			if event.source and event.source.team_id != team_id:
				# Always investigate gunshots aggressively
				if not current_target:
					set_movement_target(event.position)
					state_machine.change_state_by_name("investigate")
				elif event.position.distance_to(global_position) < 50.0:
					# Close gunshot - very high priority
					set_movement_target(event.position)
					state_machine.change_state_by_name("investigate")
				
				# Increase stress and alertness
				stress_level = min(stress_level + 0.4, 1.0)
		
		"footstep":
			if event.source and event.source.team_id != team_id:
				# Investigate enemy footsteps if we're not busy
				if not current_target and event.position.distance_to(global_position) < 30.0:
					set_movement_target(event.position)
					state_machine.change_state_by_name("investigate")
				
				stress_level = min(stress_level + 0.2, 1.0)
		
		"reload":
			if event.source and event.source.team_id != team_id:
				# Enemy is reloading - aggressive opportunity
				if current_target == event.source:
					aggression = min(aggression + 0.3, 1.0)
				elif event.position.distance_to(global_position) < 40.0:
					# Close reload sound - investigate
					set_movement_target(event.position)
					state_machine.change_state_by_name("investigate")
		
		"explosion":
			# Always investigate explosions
			if event.position.distance_to(global_position) < 100.0:
				set_movement_target(event.position)
				state_machine.change_state_by_name("investigate")
				stress_level = min(stress_level + 0.5, 1.0)

# Weapon system callbacks
func _on_weapon_switched(weapon_name: String):
	print(name + " switched to: " + weapon_name)

func _on_ammo_changed(current: int, max: int):
	# Check if we need to reload
	if current <= 0 and max > 0:
		if state_machine.current_state.get_script().get_global_name() != "ModernReloadState":
			state_machine.change_state_by_name("reload")

func _on_weapon_fired(weapon_name: String):
	pass

func _on_reload_started(weapon_name: String):
	is_reloading = true

func _on_reload_completed(weapon_name: String):
	is_reloading = false

# Pickup detection
func _on_pickup_detected(body):
	if body is WeaponPickUp:
		_handle_weapon_pickup(body)
	elif body.has_method("Set_Ammo"):  # Ammo pickup
		_handle_ammo_pickup(body)

func _on_pickup_area_detected(area):
	pass

func _handle_weapon_pickup(weapon_pickup: WeaponPickUp):
	if not weapon_pickup.Pick_Up_Ready:
		return
	
	# Check if we want this weapon
	if _should_pickup_weapon(weapon_pickup):
		state_machine.change_state_by_name("pickup_weapon")
		# Store reference for pickup state
		set_meta("target_pickup", weapon_pickup)

func _handle_ammo_pickup(ammo_pickup):
	if not ammo_pickup.Pick_Up_Ready:
		return
	
	# Check if we need this ammo type
	if _should_pickup_ammo(ammo_pickup):
		state_machine.change_state_by_name("pickup_weapon")
		set_meta("target_pickup", ammo_pickup)

func _should_pickup_weapon(weapon_pickup: WeaponPickUp) -> bool:
	if not weapon_pickup.weapon or not weapon_pickup.weapon.weapon:
		return false
	
	var weapon_resource = weapon_pickup.weapon.weapon
	
	# Always pickup if we don't have this weapon type
	if not weapon_system.has_weapon(weapon_resource.weapon_name):
		return true
	
	# Check if our current weapon is low on ammo
	if weapon_system.get_current_ammo() <= 0 and weapon_system.get_reserve_ammo() <= 0:
		return true
	
	return false

func _should_pickup_ammo(ammo_pickup) -> bool:
	# Check if we have a weapon that uses this ammo type
	for slot in weapon_system.get_weapon_slots():
		if slot.weapon.weapon_name == ammo_pickup._weapon_name:
			# Check if we're low on ammo
			if slot.reserve_ammo < slot.weapon.max_ammo * 0.5:
				return true
	
	return false

func find_cover() -> Vector3:
	if not current_target:
		return Vector3.ZERO
	
	# Use environmental awareness to find cover
	if environmental_awareness and environmental_awareness.safe_areas.size() > 0:
		var closest_safe = Vector3.ZERO
		var closest_distance = INF
		
		for safe_area in environmental_awareness.safe_areas:
			var distance = global_position.distance_to(safe_area)
			if distance < closest_distance:
				closest_distance = distance
				closest_safe = safe_area
		
		if closest_safe != Vector3.ZERO:
			return closest_safe
	
	# Fallback to raycasting for cover
	var cover_spots = _find_potential_cover_spots()
	if cover_spots.is_empty():
		return Vector3.ZERO
	
	var best_spot = Vector3.ZERO
	var best_score = -INF
	
	for spot in cover_spots:
		var score = _evaluate_cover_spot(spot)
		if score > best_score:
			best_score = score
			best_spot = spot
	
	return best_spot

func _find_potential_cover_spots() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var search_radius = 15.0
	var num_samples = 16
	
	for i in range(num_samples):
		var angle = (i / float(num_samples)) * TAU
		var offset = Vector3(cos(angle), 0, sin(angle)) * search_radius
		var test_pos = global_position + offset
		
		if _position_provides_cover(test_pos):
			spots.append(test_pos)
	
	return spots

func _position_provides_cover(pos: Vector3) -> bool:
	if not current_target:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		pos + Vector3.UP,
		current_target.global_position + Vector3.UP
	)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty()

func _evaluate_cover_spot(spot: Vector3) -> float:
	var score = 0.0
	
	var distance = global_position.distance_to(spot)
	score -= distance * 0.1
	
	if current_target:
		var enemy_distance = spot.distance_to(current_target.global_position)
		var ideal_distance = 20.0
		score -= abs(enemy_distance - ideal_distance) * 0.2
	
	return score

func handle_message(msg: Message) -> void:
	if state_machine:
		state_machine.handle_message(msg)

func request_backup():
	if team_id > 0:
		var help_msg = TeamCommunication.TeamMessage.new(
			"request_backup",
			{"position": global_position, "enemy": current_target},
			self,
			TeamCommunication.MessagePriority.HIGH
		)
		TeamCommunication.broadcast(team_id, help_msg)

func set_sprinting(sprint: bool):
	is_sprinting = sprint
	navigation_agent.max_speed = sprint_speed if sprint else movement_speed

func set_crouching(crouch: bool):
	is_crouching = crouch
	navigation_agent.height = 1.2 if crouch else 1.8

# Compatibility methods for existing AI systems
func get_agent_velocity() -> Vector3:
	return velocity

# For compatibility with existing weapon systems
func Hit_Successful(damage: float, direction: Vector3 = Vector3.ZERO, position: Vector3 = Vector3.ZERO, attacker: FullyIntegratedFPSAgent = null):
	take_damage(damage, attacker)

func debug_test_systems():
	print("=== DEBUG TEST for ", name, " ===")
	print("Health System: ", health_system != null, " Health: ", health if health_system else "N/A")
	print("Weapon System: ", weapon_system != null)
	if weapon_system:
		print("  Weapon Count: ", weapon_system.get_weapon_count())
		print("  Current Weapon: ", weapon_system.current_weapon_slot.weapon.weapon_name if weapon_system.current_weapon_slot else "None")
		print("  Can Fire: ", weapon_system.can_fire())
	print("In Target Group: ", is_in_group("Target"))
	print("Collision Layer: ", collision_layer)
	print("===========================")
