# FPSAgent - A basic agent that combines movement, states, and goals.
# This is a simpler version compared to HumanLikeFPSAgent.
extends Vehicle
class_name FPSAgent

# Components
@onready var vision_system: VisionSystem = $VisionSystem
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var weapon_system: WeaponSystem = $WeaponSystem
@onready var health_system: HealthSystem = $HealthSystem

# AI Systems
var state_machine: StateMachine
var think_goal: ThinkGoal
var memory_system: MemorySystem
var fuzzy_weapon_selector: WeaponSelectionFuzzy
var team_id: int = 0

# Agent Stats
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var armor: float = 0.0

# Behavior Parameters
@export_range(0.0, 1.0) var aggression: float = 0.7
@export_range(0.0, 1.0) var accuracy: float = 0.8
@export_range(0.0, 1.0) var reaction_time: float = 0.2
@export_range(0.0, 1.0) var team_loyalty: float = 0.9

# Internal State
var current_target: GameEntity = null
var last_known_enemy_position: Vector3
var time_since_last_enemy_seen: float = 0.0
var is_reloading: bool = false
var stress_level: float = 0.0

signal on_death
signal on_damage(amount: float, attacker: GameEntity)

func _ready():
	super._ready()
	_initialize_ai_systems()
	_setup_state_machine()
	_setup_goals()
	
	if health_system:
		health_system.health_depleted.connect(_on_health_depleted)
		health_system.health_changed.connect(func(current, max): health = current)

func _initialize_ai_systems():
	memory_system = MemorySystem.new()
	fuzzy_weapon_selector = WeaponSelectionFuzzy.new()
	
	if vision_system:
		vision_system.owner_entity = self
		vision_system.memory_system = memory_system

func _setup_state_machine():
	state_machine = StateMachine.new(self)
	state_machine.add_state("idle", IdleState.new())
	state_machine.add_state("patrol", PatrolState.new())
	state_machine.add_state("combat", CombatState.new())
	state_machine.add_state("seek_cover", SeekCoverState.new())
	state_machine.add_state("reload", ReloadState.new())
	state_machine.add_state("heal", HealState.new())
	state_machine.add_state("dead", DeadState.new())
	state_machine.change_state_by_name("patrol")

func _setup_goals():
	think_goal = ThinkGoal.new(self)
	think_goal.add_evaluator(AttackEvaluator.new())
	think_goal.add_evaluator(ExploreEvaluator.new())
	think_goal.add_evaluator(GetHealthEvaluator.new())
	think_goal.add_evaluator(GetWeaponEvaluator.new())
	think_goal.add_evaluator(HelpTeammateEvaluator.new())

func update(delta: float) -> void:
	super.update(delta)
	if not active: return

	if vision_system:
		vision_system.update()
	
	if state_machine:
		state_machine.update(delta)
	
	if think_goal:
		think_goal.process(delta)
	
	_update_stress_level(delta)
	_update_weapon_selection()

func _update_stress_level(delta: float):
	if current_target:
		stress_level = min(stress_level + delta * 0.5, 1.0)
	elif health < max_health * 0.3:
		stress_level = min(stress_level + delta * 0.3, 1.0)
	else:
		stress_level = max(stress_level - delta * 0.2, 0.0)

func _update_weapon_selection():
	if not current_target or not weapon_system or not weapon_system.current_weapon:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	var current_ammo = weapon_system.get_current_ammo()
	
	var scores = fuzzy_weapon_selector.evaluate_weapon(distance, current_ammo)
	
	var best_weapon = ""
	var best_score = -INF
	
	for weapon_name in scores:
		if scores[weapon_name] > best_score and weapon_system.has_weapon(weapon_name):
			best_score = scores[weapon_name]
			best_weapon = weapon_name
	
	if best_weapon != "" and best_weapon != weapon_system.current_weapon.name:
		weapon_system.switch_weapon(best_weapon)

func handle_message(msg: Message) -> bool:
	if state_machine.handle_message(msg):
		return true
	
	# Handle other messages if needed
	return false

func take_damage(amount: float, attacker: GameEntity = null):
	if not health_system or health <= 0: return
	health_system.take_damage(amount)
	on_damage.emit(amount, attacker)
	
	if health > 0:
		stress_level = min(stress_level + 0.3, 1.0)
		if attacker and not current_target:
			current_target = attacker
			state_machine.change_state_by_name("combat")

func _on_health_depleted():
	state_machine.change_state_by_name("dead")
	on_death.emit()

func find_cover() -> Vector3:
	if not current_target:
		return Vector3.ZERO
	
	# Find cover positions by sampling points around the agent
	var cover_spots = _find_potential_cover_spots()
	if cover_spots.is_empty():
		return Vector3.ZERO
	
	# Evaluate each cover spot and find the best one
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
		
		# Check if the position provides cover from the current target
		if _position_provides_cover(test_pos):
			spots.append(test_pos)
	
	return spots

func _position_provides_cover(pos: Vector3) -> bool:
	if not current_target:
		return false
	
	# A position provides cover if a raycast to the target is blocked by world geometry
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		pos + Vector3.UP, # Check from agent's head height
		current_target.global_position + Vector3.UP
	)
	query.collision_mask = 1 # World geometry layer
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty()

func _evaluate_cover_spot(spot: Vector3) -> float:
	var score = 0.0
	
	# Prefer closer cover spots
	var distance = global_position.distance_to(spot)
	score -= distance * 0.1
	
	# Prefer spots at an ideal distance from the enemy
	if current_target:
		var enemy_distance = spot.distance_to(current_target.global_position)
		var ideal_distance = 20.0
		score -= abs(enemy_distance - ideal_distance) * 0.2
	
	return score
