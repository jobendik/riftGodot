# Message System for inter-entity communication
extends RefCounted
class_name Message

var sender: GameEntity
var receiver: GameEntity
var message_type: String
var data: Dictionary = {}
var delay: float = 0.0
var dispatch_time: float = 0.0
