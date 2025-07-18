# Triangular Fuzzy Set
extends FuzzySet
class_name TriangleFuzzySet

var left_offset: float
var peak: float
var right_offset: float

func _init(p: float, l_offset: float, r_offset: float):
	peak = p
	left_offset = l_offset
	right_offset = r_offset
	representative_value = peak
	min_bound = peak - left_offset
	max_bound = peak + right_offset

func calculate_dom(value: float) -> float:
	if (right_offset == 0.0 and peak == value) or (left_offset == 0.0 and peak == value):
		return 1.0
		
	var dom = 0.0
	if (value > min_bound) and (value < peak):
		dom = (value - min_bound) / left_offset
	elif (value >= peak) and (value < max_bound):
		dom = (max_bound - value) / right_offset
		
	return dom
