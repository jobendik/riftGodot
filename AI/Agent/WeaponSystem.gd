# Weapon System
extends Node3D
class_name WeaponSystem

var weapons: Dictionary = {} # weapon_name -> Weapon
var current_weapon: Weapon = null

signal weapon_switched(weapon_name: String)
signal ammo_changed(current: int, max: int)

func add_weapon(name: String, weapon: Weapon) -> void:
	weapons[name] = weapon
	weapon.weapon_system = self
	weapon.visible = false
	add_child(weapon)
	
	# If this is the first weapon, equip it
	if not current_weapon:
		switch_weapon(name)

func switch_weapon(name: String) -> void:
	if name in weapons and weapons[name] != current_weapon:
		if current_weapon:
			current_weapon.holster()
		
		current_weapon = weapons[name]
		current_weapon.draw()
		weapon_switched.emit(name)

func has_weapon(name: String) -> bool:
	return name in weapons

func get_current_ammo() -> int:
	if current_weapon:
		return current_weapon.current_ammo
	return 0

func can_fire() -> bool:
	return current_weapon != null and current_weapon.can_fire()

func fire_at(target_position: Vector3) -> void:
	if not can_fire():
		return
	
	# Apply accuracy spread
	var agent = get_parent() as FPSAgent
	var aim_offset = Vector3.ZERO
	if agent:
		var spread = (1.0 - agent.accuracy) * 0.1
		aim_offset = Vector3(
			randf_range(-spread, spread),
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		)
	
	current_weapon.fire(target_position + aim_offset)
