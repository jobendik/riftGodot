# State Machine System - For state-driven AI behavior
extends RefCounted
class_name StateMachine

var owner: GameEntity
var current_state: State
var previous_state: State
var global_state: State
var states: Dictionary = {} # String -> State

func _init(entity: GameEntity):
	owner = entity

func update(delta: float) -> void:
	if global_state:
		global_state.execute(owner, delta)
	
	if current_state:
		current_state.execute(owner, delta)

func change_state(new_state: State) -> void:
	if not new_state:
		return
	
	previous_state = current_state
	
	if current_state:
		current_state.exit(owner)
	
	current_state = new_state
	current_state.enter(owner)

func change_state_by_name(state_name: String) -> void:
	if state_name in states:
		change_state(states[state_name])
	else:
		printerr("State not found: ", state_name)

func revert_to_previous_state() -> void:
	if previous_state:
		change_state(previous_state)

func add_state(name: String, state: State) -> void:
	states[name] = state

func handle_message(msg: Message) -> bool:
	if current_state and current_state.on_message(owner, msg):
		return true
	
	if global_state and global_state.on_message(owner, msg):
		return true
	
	return false
