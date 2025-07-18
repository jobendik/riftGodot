# Vision System - Line of sight and visibility checks
extends Node3D
class_name VisionSystem

@export var fov_degrees: float = 120.0
@export var range: float = 30.0
@export var check_visibility: bool = true
var owner_entity: GameEntity
var memory_system: MemorySystem
var visible_entities: Array[GameEntity] = []

func _ready():
	# The memory system should be assigned by the owner agent
	if not memory_system:
		memory_system = MemorySystem.new()

func update() -> void:
	visible_entities.clear()
	
	if not owner_entity or not owner_entity.entity_manager:
		return
	
	var potential_targets = owner_entity.entity_manager.get_neighbors(owner_entity, range)
	
	for target in potential_targets:
		if target == owner_entity:
			continue
			
		if can_see(target):
			visible_entities.append(target)
			_update_memory_record(target, true)
		else:
			_update_memory_record(target, false)
	
	if memory_system:
		memory_system.update(owner_entity)

func can_see(target: GameEntity) -> bool:
	if not is_instance_valid(target):
		return false
		
	# Check range
	var distance = global_position.distance_to(target.global_position)
	if distance > range:
		return false
	
	# Check FOV
	var to_target = (target.global_position - global_position).normalized()
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_target))
	
	if angle > fov_degrees * 0.5:
		return false
	
	# Line of sight check
	if check_visibility:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			global_position, 
			target.global_position
		)
		query.collision_mask = 1 # Assumes world geometry is on layer 1
		query.exclude = [owner_entity.get_instance_id()]
		
		var result = space_state.intersect_ray(query)
		if result and result.collider != target:
			return false
	
	return true

func _update_memory_record(entity: GameEntity, visible: bool) -> void:
	if not memory_system:
		return
		
	var record = memory_system.get_record(entity)
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if not record:
		record = memory_system.create_record(entity)
	
	record.last_sensed_position = entity.global_position
	record.time_last_sensed = current_time
	
	if visible:
		if not record.visible:
			record.time_became_visible = current_time
		record.time_last_visible = current_time
		record.visible = true
	else:
		record.visible = false
