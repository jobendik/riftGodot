# Base Weapon class
extends Node3D
class_name Weapon

@export var damage: float = 20.0
@export var fire_rate: float = 0.2
@export var max_ammo: int = 30
@export var reload_time: float = 2.0
@export var range: float = 100.0

var current_ammo: int
var time_since_last_shot: float = 0.0
var is_reloading: bool = false
var weapon_system: WeaponSystem

func _ready():
	current_ammo = max_ammo
	time_since_last_shot = fire_rate # Can fire immediately

func _process(delta: float):
	time_since_last_shot += delta

func can_fire() -> bool:
	return current_ammo > 0 and not is_reloading and time_since_last_shot >= fire_rate

func fire(target_position: Vector3) -> void:
	if not can_fire():
		return
	
	current_ammo -= 1
	time_since_last_shot = 0.0
	
	# Create projectile or perform a raycast for the shot
	_perform_shot(target_position)
	
	if weapon_system:
		weapon_system.ammo_changed.emit(current_ammo, max_ammo)
	
	if current_ammo == 0:
		reload()

func reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	
	is_reloading = true
	var timer = get_tree().create_timer(reload_time)
	await timer.timeout
	current_ammo = max_ammo
	is_reloading = false
	
	if weapon_system:
		weapon_system.ammo_changed.emit(current_ammo, max_ammo)

func _perform_shot(target_position: Vector3) -> void:
	# Example raycast shot implementation
	var world = get_world_3d()
	if not world: return
	
	var space_state = world.direct_space_state
	var from = global_position
	var to = from + (target_position - from).normalized() * range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 2 # Assume world is layer 1, agents are layer 2
	if get_parent():
		query.exclude = [get_parent().get_instance_id()]
	
	var result = space_state.intersect_ray(query)
	if result:
		var body = result.collider
		if body and body.has_method("take_damage"):
			body.take_damage(damage, get_parent())

func draw() -> void:
	visible = true

func holster() -> void:
	visible = false
