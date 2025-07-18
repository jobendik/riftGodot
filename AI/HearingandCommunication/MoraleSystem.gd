# Morale and Emotion System
extends RefCounted
class_name MoraleSystem

var owner_agent: HumanLikeFPSAgent
var morale: float = 0.7      # General willingness to fight (0=low, 1=high)
var fear: float = 0.1        # Immediate sense of danger (0=low, 1=high)
var confidence: float = 0.5  # Belief in one's own success (0=low, 1=high)
var fatigue: float = 0.0     # Physical exhaustion (0=low, 1=high)

# Emotion states triggered by thresholds
var is_panicking: bool = false
var is_rallying: bool = false
var is_berserk: bool = false

signal morale_changed(new_morale: float)
signal emotion_state_changed(state: String)

func _init(agent: HumanLikeFPSAgent):
	owner_agent = agent

func update(delta: float) -> void:
	# Fatigue increases slowly over time
	fatigue = min(fatigue + delta * 0.005, 1.0)
	
	# Morale and fear naturally decay towards a neutral state
	var old_morale = morale
	morale = lerp(morale, 0.5, delta * 0.05)
	fear = lerp(fear, 0.0, delta * 0.2)
	
	if abs(morale - old_morale) > 0.01:
		morale_changed.emit(morale)
	
	check_emotion_states()

func check_emotion_states() -> void:
	var previous_panicking = is_panicking
	var previous_rallying = is_rallying
	var previous_berserk = is_berserk
	
	# Check for panic (low morale, high fear)
	is_panicking = morale < 0.2 and fear > 0.8
	# Check for rallying (high morale and confidence)
	is_rallying = morale > 0.9 and confidence > 0.8
	# Check for berserk (critically wounded but aggressive)
	is_berserk = owner_agent.health < owner_agent.max_health * 0.15 and owner_agent.aggression > 0.9
	
	# Emit signals only when the state changes
	if is_panicking and not previous_panicking:
		emotion_state_changed.emit("panic")
	if is_rallying and not previous_rallying:
		emotion_state_changed.emit("rally")
	if is_berserk and not previous_berserk:
		emotion_state_changed.emit("berserk")

func on_ally_killed() -> void:
	morale = clamp(morale - 0.2, 0.0, 1.0)
	fear = clamp(fear + 0.3, 0.0, 1.0)

func on_enemy_killed() -> void:
	morale = clamp(morale + 0.15, 0.0, 1.0)
	confidence = clamp(confidence + 0.2, 0.0, 1.0)
	fear = clamp(fear - 0.1, 0.0, 1.0)

func on_objective_captured() -> void:
	morale = clamp(morale + 0.3, 0.0, 1.0)
	confidence = clamp(confidence + 0.3, 0.0, 1.0)
	fatigue = max(0, fatigue - 0.5) # Recover from fatigue
