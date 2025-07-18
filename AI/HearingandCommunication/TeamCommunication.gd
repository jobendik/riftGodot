# Team Communication System
extends Node
class_name TeamCommunication

enum MessagePriority { LOW, MEDIUM, HIGH, CRITICAL }

class TeamMessage extends RefCounted:
	var type: String
	var data: Dictionary
	var sender: FPSAgent
	var priority: MessagePriority
	var position: Vector3
	var timestamp: float
	
	func _init(msg_type: String, msg_data: Dictionary, agent: FPSAgent, prio: MessagePriority = MessagePriority.MEDIUM):
		type = msg_type
		data = msg_data
		sender = agent
		priority = prio
		position = agent.global_position
		timestamp = Time.get_ticks_msec() / 1000.0

static var team_channels: Dictionary = {} # team_id -> Array[TeamMessage]

static func broadcast(team_id: int, message: TeamMessage) -> void:
	if not team_id in team_channels:
		team_channels[team_id] = []
	
	team_channels[team_id].append(message)
	
	# Clean up old messages to prevent memory leaks
	var current_time = Time.get_ticks_msec() / 1000.0
	team_channels[team_id] = team_channels[team_id].filter(
		func(msg): return current_time - msg.timestamp < 10.0
	)

static func get_team_messages(team_id: int) -> Array:
	if team_id in team_channels:
		return team_channels[team_id]
	return []
