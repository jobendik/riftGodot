# Memory System - For AI perception and memory
extends RefCounted
class_name MemorySystem

class MemoryRecord extends RefCounted:
	var entity: GameEntity
	var last_sensed_position: Vector3
	var time_last_sensed: float
	var time_became_visible: float
	var time_last_visible: float
	var visible: bool = false
	var data: Dictionary = {}

var records: Dictionary = {} # entity_uuid -> MemoryRecord
var memory_span: float = 10.0 # How long to remember entities

func update(owner_entity: GameEntity) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Clean old memories
	var to_remove = []
	for uuid in records:
		var record = records[uuid]
		if current_time - record.time_last_sensed > memory_span:
			to_remove.append(uuid)
	
	for uuid in to_remove:
		records.erase(uuid)

func create_record(entity: GameEntity) -> MemoryRecord:
	if has_record(entity):
		return get_record(entity)
		
	var record = MemoryRecord.new()
	record.entity = entity
	record.time_last_sensed = Time.get_ticks_msec() / 1000.0
	records[entity.uuid] = record
	return record

func get_record(entity: GameEntity) -> MemoryRecord:
	if entity and entity.uuid in records:
		return records[entity.uuid]
	return null

func has_record(entity: GameEntity) -> bool:
	return entity and entity.uuid in records
