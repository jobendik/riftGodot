# Base Fuzzy Set
extends RefCounted
class_name FuzzySet

var dom: float = 0.0 # Degree of Membership
var representative_value: float = 0.0
var min_bound: float = 0.0
var max_bound: float = 0.0

func calculate_dom(value: float) -> float:
	# To be implemented by subclasses (Triangle, Trapezoid, etc.)
	return 0.0

func clear_dom() -> void:
	dom = 0.0

func or_with_dom(value: float) -> void:
	# Used by rules to set the DOM of consequent sets
	dom = max(dom, value)
