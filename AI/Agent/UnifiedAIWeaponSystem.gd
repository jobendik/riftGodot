# Unified AI Weapon System - Uses the same WeaponResource system as player
extends Node3D
class_name UnifiedAIWeaponSystem

# Use the same weapon slot system as player
var weapon_slots: Array[WeaponSlot] = []
var current_weapon_slot: WeaponSlot = null
var max_weapons: int = 4

# Reference to owner agent
var owner_agent: ModernFPSAgent

# Weapon management
var weapon_switch_cooldown: float = 0.0
var reload_cooldown: float = 0.0
var fire_cooldown: float = 0.0

# Bullet point for projectile spawning (like player system)
@onready var bullet_point: Marker3D = $BulletPoint

# Signals matching player weapon system
signal weapon_switched(weapon_name: String)
signal ammo_changed(current: int, max: int)
signal weapon_fired(weapon_name: String)
signal reload_started(weapon_name: String)
signal reload_completed(weapon_name: String)

func _init(agent: ModernFPSAgent = null):
	owner_agent = agent

func _ready():
	# Create bullet point if it doesn't exist
	if not bullet_point:
		bullet_point = Marker3D.new()
		bullet_point.name = "BulletPoint"
		bullet_point.position = Vector3(0, 1.6, 0.5)  # Roughly chest height, slightly forward
		add_child(bullet_point)

func _process(delta):
	# Update cooldowns
	weapon_switch_cooldown = max(0, weapon_switch_cooldown - delta)
	reload_cooldown = max(0, reload_cooldown - delta)
	fire_cooldown = max(0, fire_cooldown - delta)

# Add weapon using WeaponSlot (same as player)
func add_weapon_slot(weapon_slot: WeaponSlot) -> bool:
	if weapon_slots.size() >= max_weapons:
		return false
	
	weapon_slots.append(weapon_slot)
	
	# If this is the first weapon, equip it
	if current_weapon_slot == null:
		switch_to_weapon_slot(weapon_slot)
	
	return true

# Create weapon slot from WeaponResource (for initial loadout)
func add_weapon_from_resource(weapon_resource: WeaponResource, current_ammo: int = -1, reserve_ammo: int = -1) -> bool:
	if weapon_slots.size() >= max_weapons:
		return false
	
	var weapon_slot = WeaponSlot.new()
	weapon_slot.weapon = weapon_resource
	weapon_slot.current_ammo = current_ammo if current_ammo >= 0 else weapon_resource.magazine
	weapon_slot.reserve_ammo = reserve_ammo if reserve_ammo >= 0 else weapon_resource.max_ammo
	
	return add_weapon_slot(weapon_slot)

# Switch to specific weapon slot
func switch_to_weapon_slot(weapon_slot: WeaponSlot) -> bool:
	if weapon_slot == current_weapon_slot or weapon_switch_cooldown > 0:
		return false
	
	if weapon_slot not in weapon_slots:
		return false
	
	current_weapon_slot = weapon_slot
	weapon_switch_cooldown = 0.5  # AI weapon switch cooldown
	
	weapon_switched.emit(current_weapon_slot.weapon.weapon_name)
	ammo_changed.emit(current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo)
	
	return true

# Switch to weapon by name
func switch_to_weapon_by_name(weapon_name: String) -> bool:
	for slot in weapon_slots:
		if slot.weapon.weapon_name == weapon_name:
			return switch_to_weapon_slot(slot)
	return false

# Check if we have a specific weapon
func has_weapon(weapon_name: String) -> bool:
	for slot in weapon_slots:
		if slot.weapon.weapon_name == weapon_name:
			return true
	return false

# Get current ammo
func get_current_ammo() -> int:
	if current_weapon_slot:
		return current_weapon_slot.current_ammo
	return 0

# Get reserve ammo
func get_reserve_ammo() -> int:
	if current_weapon_slot:
		return current_weapon_slot.reserve_ammo
	return 0

# Check if weapon can fire
func can_fire() -> bool:
	if not current_weapon_slot or fire_cooldown > 0:
		return false
	
	var weapon = current_weapon_slot.weapon
	
	# Check if weapon has ammo (or doesn't need ammo)
	if weapon.has_ammo and current_weapon_slot.current_ammo <= 0:
		return false
	
	return true

# Fire weapon at target position
func fire_at(target_position: Vector3) -> bool:
	if not can_fire():
		return false
	
	var weapon = current_weapon_slot.weapon
	
	# Set fire cooldown based on weapon's auto_fire setting
	if weapon.auto_fire:
		fire_cooldown = 0.1  # Fast auto fire for AI
	else:
		fire_cooldown = 0.5  # Slower semi-auto fire
	
	# Consume ammo
	if weapon.has_ammo:
		current_weapon_slot.current_ammo -= 1
		ammo_changed.emit(current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo)
	
	# Create and fire projectile using the same system as player
	_fire_projectile(target_position, weapon)
	
	weapon_fired.emit(weapon.weapon_name)
	
	# Make gunshot sound
	if owner_agent and owner_agent.sound_emitter:
		owner_agent.sound_emitter.emit_gunshot(weapon.weapon_name)
	
	return true

# Fire projectile using the same system as player
func _fire_projectile(target_position: Vector3, weapon_resource: WeaponResource):
	if not weapon_resource.projectile_to_load:
		return
	
	# Instantiate projectile (same as player system)
	var projectile = weapon_resource.projectile_to_load.instantiate() as Projectile
	if not projectile:
		return
	
	# Set projectile position and rotation
	projectile.global_position = bullet_point.global_position
	projectile.global_rotation = owner_agent.global_rotation
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Calculate spread for AI (reduced for better accuracy)
	var spread = Vector2.ZERO
	if owner_agent:
		var accuracy_spread = (1.0 - owner_agent.accuracy) * 0.05  # Much tighter spread than player
		spread = Vector2(
			randf_range(-accuracy_spread, accuracy_spread),
			randf_range(-accuracy_spread, accuracy_spread)
		)
	
	# Fire projectile
	projectile._Set_Projectile(
		weapon_resource.damage,
		spread,
		weapon_resource.fire_range,
		bullet_point.global_position
	)

# Reload current weapon
func reload() -> bool:
	if not current_weapon_slot or reload_cooldown > 0:
		return false
	
	var weapon = current_weapon_slot.weapon
	
	# Check if reload is needed and possible
	if not weapon.has_ammo:
		return false
	
	if current_weapon_slot.current_ammo >= weapon.magazine:
		return false
	
	if current_weapon_slot.reserve_ammo <= 0:
		return false
	
	# Start reload
	reload_cooldown = weapon_resource_to_reload_time(weapon)
	reload_started.emit(weapon.weapon_name)
	
	# For AI, we do instant reload after cooldown
	var timer = get_tree().create_timer(reload_cooldown)
	await timer.timeout
	
	_complete_reload()
	
	return true

# Complete reload process
func _complete_reload():
	if not current_weapon_slot:
		return
	
	var weapon = current_weapon_slot.weapon
	var needed_ammo = weapon.magazine - current_weapon_slot.current_ammo
	var available_ammo = current_weapon_slot.reserve_ammo
	var reload_amount = min(needed_ammo, available_ammo)
	
	current_weapon_slot.current_ammo += reload_amount
	current_weapon_slot.reserve_ammo -= reload_amount
	
	ammo_changed.emit(current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo)
	reload_completed.emit(weapon.weapon_name)
	
	# Make reload sound
	if owner_agent and owner_agent.sound_emitter:
		owner_agent.sound_emitter.emit_reload()

# Convert weapon resource to reload time
func weapon_resource_to_reload_time(weapon_resource: WeaponResource) -> float:
	# Base reload times for different weapon types
	var base_reload_time = 2.0
	
	match weapon_resource.weapon_name.to_lower():
		"pistol", "blaster_n":
			base_reload_time = 1.5
		"rifle", "blasteri":
			base_reload_time = 2.0
		"shotgun", "blasterm":
			base_reload_time = 3.0
		"sniper":
			base_reload_time = 3.5
		"heavy", "blasterq":
			base_reload_time = 4.0
		_:
			base_reload_time = 2.0
	
	return base_reload_time

# Check if weapon needs reload
func needs_reload() -> bool:
	if not current_weapon_slot:
		return false
	
	var weapon = current_weapon_slot.weapon
	return weapon.has_ammo and current_weapon_slot.current_ammo <= 0 and current_weapon_slot.reserve_ammo > 0

# Drop current weapon (returns WeaponPickUp scene)
func drop_current_weapon() -> WeaponPickUp:
	if not current_weapon_slot:
		return null
	
	var weapon = current_weapon_slot.weapon
	if not weapon.can_be_dropped or not weapon.weapon_drop:
		return null
	
	# Create weapon drop
	var weapon_drop = weapon.weapon_drop.instantiate() as WeaponPickUp
	if not weapon_drop:
		return null
	
	# Set up weapon drop with current ammo
	weapon_drop.weapon = current_weapon_slot.duplicate()
	weapon_drop.global_position = bullet_point.global_position
	
	# Remove from our inventory
	weapon_slots.erase(current_weapon_slot)
	
	# Switch to next available weapon
	if weapon_slots.size() > 0:
		switch_to_weapon_slot(weapon_slots[0])
	else:
		current_weapon_slot = null
	
	return weapon_drop

# Pick up weapon from pickup
func pickup_weapon(weapon_pickup: WeaponPickUp) -> bool:
	if not weapon_pickup or not weapon_pickup.weapon:
		return false
	
	# Check if we already have this weapon type
	for slot in weapon_slots:
		if slot.weapon.weapon_name == weapon_pickup.weapon.weapon.weapon_name:
			# Add ammo to existing weapon
			var total_ammo = weapon_pickup.weapon.current_ammo + weapon_pickup.weapon.reserve_ammo
			var space_available = slot.weapon.max_ammo - slot.reserve_ammo
			var ammo_to_add = min(total_ammo, space_available)
			
			slot.reserve_ammo += ammo_to_add
			ammo_changed.emit(slot.current_ammo, slot.reserve_ammo)
			
			return ammo_to_add > 0
	
	# Add new weapon if we have space
	if weapon_slots.size() < max_weapons:
		return add_weapon_slot(weapon_pickup.weapon)
	
	return false

# Get best weapon for current situation
func get_best_weapon_for_distance(distance: float) -> WeaponSlot:
	var best_weapon: WeaponSlot = null
	var best_score = -1.0
	
	for slot in weapon_slots:
		var weapon = slot.weapon
		var score = 0.0
		
		# Score based on weapon effectiveness at distance
		if distance < 10:  # Close range
			match weapon.weapon_name.to_lower():
				"shotgun", "blasterm":
					score = 0.9
				"rifle", "blasteri":
					score = 0.7
				"pistol", "blaster_n":
					score = 0.6
				_:
					score = 0.5
		elif distance < 30:  # Medium range
			match weapon.weapon_name.to_lower():
				"rifle", "blasteri":
					score = 0.9
				"pistol", "blaster_n":
					score = 0.7
				"shotgun", "blasterm":
					score = 0.4
				_:
					score = 0.6
		else:  # Long range
			match weapon.weapon_name.to_lower():
				"sniper":
					score = 0.9
				"rifle", "blasteri":
					score = 0.8
				"pistol", "blaster_n":
					score = 0.5
				_:
					score = 0.3
		
		# Reduce score if low on ammo
		if weapon.has_ammo:
			var ammo_ratio = float(slot.current_ammo) / float(weapon.magazine)
			score *= (0.5 + ammo_ratio * 0.5)
		
		if score > best_score:
			best_score = score
			best_weapon = slot
	
	return best_weapon

# Get weapon slots for inventory management
func get_weapon_slots() -> Array[WeaponSlot]:
	return weapon_slots.duplicate()

# Get current weapon resource
func get_current_weapon_resource() -> WeaponResource:
	if current_weapon_slot:
		return current_weapon_slot.weapon
	return null

# Auto-switch to best weapon for situation
func auto_switch_weapon(target_distance: float = 20.0) -> bool:
	var best_weapon = get_best_weapon_for_distance(target_distance)
	if best_weapon and best_weapon != current_weapon_slot:
		return switch_to_weapon_slot(best_weapon)
	return false
