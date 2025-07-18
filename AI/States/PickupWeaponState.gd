# Pickup Weapon State - Handles weapon and ammo pickups
extends State
class_name PickupWeaponState

var target_pickup: Node = null
var approach_distance: float = 2.0
var pickup_timeout: float = 5.0
var pickup_timer: float = 0.0

func enter(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	# Get target pickup from metadata
	target_pickup = agent.get_meta("target_pickup", null)
	if not target_pickup:
		agent.state_machine.revert_to_previous_state()
		return
	
	pickup_timer = 0.0
	
	# Move towards pickup
	agent.set_movement_target(target_pickup.global_position)

func execute(owner: GameEntity, delta: float) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if not agent: return
	
	pickup_timer += delta
	
	# Check if pickup still exists
	if not is_instance_valid(target_pickup):
		agent.state_machine.change_state_by_name("patrol")
		return
	
	# Check if we're close enough to pickup
	var distance = agent.global_position.distance_to(target_pickup.global_position)
	if distance <= approach_distance:
		_attempt_pickup(agent)
		return
	
	# Timeout if taking too long
	if pickup_timer > pickup_timeout:
		agent.state_machine.change_state_by_name("patrol")
		return
	
	# If under attack, abort pickup
	if agent.current_target and agent.stress_level > 0.5:
		agent.state_machine.change_state_by_name("combat")
		return

func _attempt_pickup(agent: FullyIntegratedFPSAgent):
	var success = false
	
	if target_pickup is WeaponPickUp:
		success = _pickup_weapon(agent, target_pickup)
	elif target_pickup.has_method("Set_Ammo"):  # Ammo pickup
		success = _pickup_ammo(agent, target_pickup)
	
	if success:
		# Remove pickup from scene
		target_pickup.queue_free()
		
		# Emit pickup signal
		if target_pickup is WeaponPickUp:
			agent.weapon_picked_up.emit(target_pickup.weapon.weapon.weapon_name)
		
		# Brief pause after pickup
		await agent.get_tree().create_timer(0.5).timeout
	
	# Return to previous state
	agent.state_machine.change_state_by_name("patrol")

func _pickup_weapon(agent: FullyIntegratedFPSAgent, weapon_pickup: WeaponPickUp) -> bool:
	if not weapon_pickup.Pick_Up_Ready:
		return false
	
	# Try to pickup weapon
	var success = agent.weapon_system.pickup_weapon(weapon_pickup)
	
	if success:
		print(agent.name + " picked up weapon: " + weapon_pickup.weapon.weapon.weapon_name)
		
		# Make pickup sound
		if agent.sound_emitter:
			agent.sound_emitter.emit_voice("weapon_pickup")
	
	return success

func _pickup_ammo(agent: FullyIntegratedFPSAgent, ammo_pickup) -> bool:
	if not ammo_pickup.Pick_Up_Ready:
		return false
	
	# Find matching weapon slot
	for slot in agent.weapon_system.get_weapon_slots():
		if slot.weapon.weapon_name == ammo_pickup._weapon_name:
			# Add ammo to slot
			var space_available = slot.weapon.max_ammo - slot.reserve_ammo
			var ammo_to_add = min(ammo_pickup._reserve_ammo, space_available)
			
			if ammo_to_add > 0:
				slot.reserve_ammo += ammo_to_add
				print(agent.name + " picked up " + str(ammo_to_add) + " ammo for " + slot.weapon.weapon_name)
				
				# Make pickup sound
				if agent.sound_emitter:
					agent.sound_emitter.emit_voice("ammo_pickup")
				
				return true
	
	return false

func exit(owner: GameEntity) -> void:
	var agent = owner as FullyIntegratedFPSAgent
	if agent:
		agent.remove_meta("target_pickup")
