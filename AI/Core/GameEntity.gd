# Base Game Entity - Equivalent to Yuka's GameEntity but extends CharacterBody3D
extends CharacterBody3D
class_name GameEntity

var entity_manager: EntityManager
var uuid: String = ""
var world_matrix: Transform3D = Transform3D.IDENTITY
var neighbors: Array[GameEntity] = []
var update_neighbors_radius: float = 10.0
var children: Array[GameEntity] = []
var parent: GameEntity = null
var components: Dictionary = {}
var active: bool = true

func _init():
	uuid = generate_uuid()

func _ready():
	set_physics_process(active)

func update(delta: float) -> void:
	# Override in subclasses
	pass

func update_neighbors() -> void:
	neighbors.clear()
	if entity_manager:
		neighbors = entity_manager.get_neighbors(self, update_neighbors_radius)

func add_child_entity(entity: GameEntity) -> void:
	children.append(entity)
	entity.parent = self

func remove_child_entity(entity: GameEntity) -> void:
	children.erase(entity)
	entity.parent = null

func generate_uuid() -> String:
	# A more robust UUID generation for a real project is recommended
	return "entity_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func handle_message(msg: Message) -> void:
	# To be implemented in subclasses
	pass

func can_see(target: GameEntity) -> bool:
	# Basic line-of-sight check
	if not target or not is_instance_valid(target):
		return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		target.global_position + Vector3.UP
	)
	query.collision_mask = 1
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()
