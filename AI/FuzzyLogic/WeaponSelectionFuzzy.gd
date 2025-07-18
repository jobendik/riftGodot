# ==============================================
# WeaponSelectionFuzzy.gd
# Location: AI/FuzzyLogic/WeaponSelectionFuzzy.gd
# ==============================================
extends RefCounted
class_name WeaponSelectionFuzzy

var distance_var: FuzzyVariable
var ammo_var: FuzzyVariable
var weapon_var: FuzzyVariable

func _init():
	_setup_fuzzy_variables()

func _setup_fuzzy_variables():
	# Distance fuzzy variable
	distance_var = FuzzyVariable.new("distance")
	distance_var.add_set("close", TriangleFuzzySet.new(5, 5, 10))
	distance_var.add_set("medium", TriangleFuzzySet.new(20, 15, 15))
	distance_var.add_set("far", TriangleFuzzySet.new(50, 30, 20))
	
	# Ammo fuzzy variable
	ammo_var = FuzzyVariable.new("ammo")
	ammo_var.add_set("low", TriangleFuzzySet.new(0, 0, 30))
	ammo_var.add_set("medium", TriangleFuzzySet.new(50, 30, 30))
	ammo_var.add_set("high", TriangleFuzzySet.new(100, 50, 0))
	
	# Weapon preference fuzzy variable
	weapon_var = FuzzyVariable.new("weapon")
	weapon_var.add_set("pistol", TriangleFuzzySet.new(0.3, 0.3, 0.4))
	weapon_var.add_set("rifle", TriangleFuzzySet.new(0.7, 0.3, 0.3))
	weapon_var.add_set("shotgun", TriangleFuzzySet.new(0.2, 0.2, 0.3))

func select_weapon(distance: float, ammo_level: float) -> String:
	# Simple weapon selection based on distance
	if distance < 10:
		return "shotgun"
	elif distance < 30:
		return "rifle"
	else:
		return "rifle"  # Default to rifle for long range
