# Entity Manager - Manages all game entities
extends Node
class_name EntityManager

var entities: Array[GameEntity] = []
var _message_dispatcher: MessageDispatcher

func _ready():
	_message_dispatcher = MessageDispatcher.new()
	_message_dispatcher.entity_manager = self

func add(entity: GameEntity) -> void:
	if entity not in entities:
		entities.append(entity)
		entity.entity_manager = self

func remove(entity: GameEntity) -> void:
	entities.erase(entity)
	entity.entity_manager = null

func update(delta: float) -> void:
	for entity in entities:
		if entity.active:
			entity.update(delta)
	
	_message_dispatcher.dispatch_delayed_messages(delta)

func get_neighbors(entity: GameEntity, radius: float) -> Array[GameEntity]:
	var result: Array[GameEntity] = []
	var position = entity.global_position
	
	for other in entities:
		if other != entity and is_instance_valid(other) and other.global_position.distance_to(position) <= radius:
			result.append(other)
	
	return result

func get_entities_in_region(region: AABB) -> Array[GameEntity]:
	var result: Array[GameEntity] = []
	for entity in entities:
		if is_instance_valid(entity) and region.has_point(entity.global_position):
			result.append(entity)
	return result
