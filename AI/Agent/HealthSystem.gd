# Health System
extends Node
class_name HealthSystem

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var armor: float = 0.0
@export var health_regeneration_rate: float = 0.0

signal health_changed(current: float, max: float)
signal health_depleted()

func _ready():
	current_health = max_health

func _process(delta: float):
	if health_regeneration_rate > 0 and current_health < max_health and current_health > 0:
		heal(health_regeneration_rate * delta)

func take_damage(amount: float) -> float:
	if current_health <= 0: return 0.0
	
	var actual_damage = amount * (1.0 - (armor / 100.0))
	current_health = max(0, current_health - actual_damage)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		health_depleted.emit()
	
	return actual_damage

func heal(amount: float) -> void:
	if current_health <= 0: return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
