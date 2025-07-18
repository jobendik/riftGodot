# Environmental Awareness System
extends RefCounted
class_name EnvironmentalAwareness

var owner_agent: FullyIntegratedFPSAgent
var known_items: Dictionary = {} # position -> item_type
var dangerous_areas: Array[Vector3] = []
var safe_areas: Array[Vector3] = []
var last_death_positions: Array[Vector3] = []
var map_knowledge: float = 0.0 # 0-1 how well the agent knows the map

func _init(agent: FullyIntegratedFPSAgent):
	owner_agent = agent

func update() -> void:
	# Scan for nearby items periodically, not every frame
	if randf() < 0.1:
		scan_for_items()
	
	# Update map knowledge slowly over time
	map_knowledge = min(map_knowledge + 0.0001, 1.0)
	
	# Update dangerous areas based on combat
	if owner_agent.current_target:
		mark_area_dangerous(owner_agent.current_target.global_position)

func scan_for_items() -> void:
	# This requires a proper setup with items on a specific physics layer
	var scan_radius = 15.0
	var space_state = owner_agent.get_world_3d().direct_space_state
	
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = scan_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), owner_agent.global_position)
	query.collision_mask = 8 # Assumes items are on layer 8
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var item = result.collider
		if item.has_method("get_item_type"):
			known_items[item.global_position] = item.get_item_type()

func mark_area_dangerous(position: Vector3, radius: float = 5.0) -> void:
	dangerous_areas.append(position)
	
	# Limit array size to prevent memory issues
	if dangerous_areas.size() > 20:
		dangerous_areas.pop_front()

func on_death_witnessed(position: Vector3) -> void:
	last_death_positions.append(position)
	mark_area_dangerous(position, 8.0)
	
	if last_death_positions.size() > 10:
		last_death_positions.pop_front()
