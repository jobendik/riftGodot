# Fuzzy Variable
extends RefCounted
class_name FuzzyVariable

var name: String
var sets: Dictionary = {} # String -> FuzzySet
var min_range: float = 0.0
var max_range: float = 1.0

func _init(var_name: String):
	name = var_name

func add_set(set_name: String, fuzzy_set: FuzzySet) -> FuzzySet:
	sets[set_name] = fuzzy_set
	adjust_range(fuzzy_set)
	return fuzzy_set

func fuzzify(value: float) -> void:
	# Calculate the Degree of Membership (DOM) for each set in this variable
	for set_name in sets:
		sets[set_name].dom = sets[set_name].calculate_dom(value)

func defuzzify(method: String = "max_av") -> float:
	# Convert the fuzzy output back to a crisp value
	match method:
		"max_av":
			return defuzzify_max_av()
		# Other methods like "centroid" could be added here
		_:
			return defuzzify_max_av()

func defuzzify_max_av() -> float:
	var sum_dom_x_rep = 0.0
	var sum_of_doms = 0.0
	
	for set_name in sets:
		var fuzzy_set = sets[set_name]
		sum_dom_x_rep += fuzzy_set.dom * fuzzy_set.representative_value
		sum_of_doms += fuzzy_set.dom
	
	if sum_of_doms == 0:
		return 0.0
	
	return sum_dom_x_rep / sum_of_doms

func reset_consequents() -> void:
	# Reset the DOM for all sets in this variable
	for set_name in sets:
		sets[set_name].clear_dom()

func adjust_range(fuzzy_set: FuzzySet):
	# Automatically adjust the min/max range of this variable to encompass all its sets
	if sets.size() == 1:
		min_range = fuzzy_set.min_bound
		max_range = fuzzy_set.max_bound
	else:
		min_range = min(min_range, fuzzy_set.min_bound)
		max_range = max(max_range, fuzzy_set.max_bound)
