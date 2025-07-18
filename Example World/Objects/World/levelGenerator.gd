@tool
extends Node3D

# Improved FPS Level with REAL windows, doors, and ramps!

@export var arena_size = Vector3(300, 0, 300): set = set_arena_size
@export var generate_level: bool = false: set = trigger_generation
@export var clear_level: bool = false: set = trigger_clear
@export var enable_debug_markers: bool = true: set = set_debug_markers
@export var create_navmesh: bool = true: set = set_create_navmesh

var spawn_points: Array[Vector3] = []
var strategic_positions: Array[Vector3] = []
var weapon_spawn_points: Array[Vector3] = []
var cover_positions: Array[Vector3] = []
var materials: Dictionary = {}

func set_arena_size(value: Vector3):
	arena_size = value
	if Engine.is_editor_hint():
		notify_property_list_changed()

func set_debug_markers(value: bool):
	enable_debug_markers = value
	if Engine.is_editor_hint():
		update_debug_markers()

func set_create_navmesh(value: bool):
	create_navmesh = value

func trigger_generation(value: bool):
	if value and Engine.is_editor_hint():
		generate_improved_fps_level()
		generate_level = false
		notify_property_list_changed()

func trigger_clear(value: bool):
	if value and Engine.is_editor_hint():
		clear_all_children()
		clear_level = false
		notify_property_list_changed()

func generate_improved_fps_level():
	if not Engine.is_editor_hint():
		return
	
	print("🔥 Generating IMPROVED FPS Level with Windows, Doors & Ramps...")
	
	clear_all_children()
	setup_materials()
	
	# 1. Foundation
	create_main_arena()
	
	# 2. Central compound with REAL windows and doors
	create_central_compound_with_openings()
	
	# 3. Multi-level buildings with proper access
	create_multi_level_buildings()
	
	# 4. Spawn facilities with doors
	create_spawn_facilities_with_doors()
	
	# 5. Sniper towers with ladder access
	create_sniper_towers_with_access()
	
	# 6. Connecting bridges and walkways
	create_connecting_walkways()
	
	# 7. Tactical ramps everywhere
	create_tactical_ramp_system()
	
	# 8. Weapon rooms with entrances
	create_weapon_rooms_with_entrances()
	
	# 9. Advanced cover with varying heights
	create_advanced_cover_system()
	
	# 10. Choke points with actual passages
	create_choke_points_with_passages()
	
	# 11. Underground with proper access
	create_underground_with_access()
	
	# 12. Special areas and details
	create_special_areas_and_details()
	
	# 13. Navigation and lighting
	if create_navmesh:
		create_navigation_system()
	setup_lighting()
	
	call_deferred("set_all_owners")
	
	if enable_debug_markers:
		call_deferred("add_debug_markers")
	
	print("✅ IMPROVED FPS Level Complete! Now with REAL gameplay elements!")

func setup_materials():
	materials.clear()
	
	# Enhanced materials with more variety
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.25, 0.3)
	floor_mat.metallic = 0.1
	floor_mat.roughness = 0.8
	materials["floor"] = floor_mat
	
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.4, 0.4, 0.45)
	wall_mat.metallic = 0.2
	wall_mat.roughness = 0.7
	materials["wall"] = wall_mat
	
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.6, 0.6, 0.65)
	metal_mat.metallic = 0.9
	metal_mat.roughness = 0.2
	materials["metal"] = metal_mat
	
	var ramp_mat = StandardMaterial3D.new()
	ramp_mat.albedo_color = Color(0.3, 0.4, 0.5)
	ramp_mat.metallic = 0.7
	ramp_mat.roughness = 0.3
	materials["ramp"] = ramp_mat
	
	var cover_mat = StandardMaterial3D.new()
	cover_mat.albedo_color = Color(0.2, 0.2, 0.25)
	cover_mat.metallic = 0.1
	cover_mat.roughness = 0.9
	materials["cover"] = cover_mat
	
	var spawn_mat = StandardMaterial3D.new()
	spawn_mat.albedo_color = Color(0.3, 0.5, 0.3)
	spawn_mat.metallic = 0.3
	spawn_mat.roughness = 0.6
	materials["spawn"] = spawn_mat
	
	var weapon_mat = StandardMaterial3D.new()
	weapon_mat.albedo_color = Color(0.5, 0.3, 0.3)
	weapon_mat.metallic = 0.4
	weapon_mat.roughness = 0.5
	materials["weapon"] = weapon_mat
	
	var strategic_mat = StandardMaterial3D.new()
	strategic_mat.albedo_color = Color(0.3, 0.3, 0.5)
	strategic_mat.metallic = 0.6
	strategic_mat.roughness = 0.4
	materials["strategic"] = strategic_mat
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.8, 0.9, 0.3)
	glass_mat.metallic = 0.0
	glass_mat.roughness = 0.0
	glass_mat.flags_transparent = true
	materials["glass"] = glass_mat

func create_main_arena():
	var floor = StaticBody3D.new()
	floor.name = "Main_Arena_Floor"
	
	var floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "FloorMesh"
	floor_mesh.material_override = materials["floor"]
	
	var floor_collision = CollisionShape3D.new()
	floor_collision.name = "FloorCollision"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(arena_size.x, 2, arena_size.z)
	
	floor_mesh.mesh = box_mesh
	floor_mesh.position = Vector3(0, -1, 0)
	
	floor_collision.shape = box_mesh.create_trimesh_shape()
	floor_collision.position = Vector3(0, -1, 0)
	
	floor.add_child(floor_mesh)
	floor.add_child(floor_collision)
	add_child(floor)
	
	# Arena walls with actual entrances
	create_arena_walls_with_entrances()

func create_arena_walls_with_entrances():
	var wall_container = Node3D.new()
	wall_container.name = "Arena_Walls"
	add_child(wall_container)
	
	var wall_height = 12
	var wall_thickness = 3
	
	# Create walls with gaps for entrances
	create_wall_with_entrance(wall_container, Vector3(0, wall_height/2, arena_size.z/2), Vector3(arena_size.x, wall_height, wall_thickness), "North")
	create_wall_with_entrance(wall_container, Vector3(0, wall_height/2, -arena_size.z/2), Vector3(arena_size.x, wall_height, wall_thickness), "South")
	create_wall_with_entrance(wall_container, Vector3(arena_size.x/2, wall_height/2, 0), Vector3(wall_thickness, wall_height, arena_size.z), "East")
	create_wall_with_entrance(wall_container, Vector3(-arena_size.x/2, wall_height/2, 0), Vector3(wall_thickness, wall_height, arena_size.z), "West")

func create_wall_with_entrance(parent: Node3D, pos: Vector3, size: Vector3, direction: String):
	var wall_section = Node3D.new()
	wall_section.name = "Wall_" + direction
	parent.add_child(wall_section)
	
	# Create wall in segments with gap in middle
	var segment_size = size
	var entrance_width = 15
	
	if direction == "North" or direction == "South":
		segment_size.x = (size.x - entrance_width) / 2
		# Left segment
		var left_wall = create_textured_structure(segment_size, Vector3(pos.x - entrance_width/2 - segment_size.x/2, pos.y, pos.z), "wall")
		wall_section.add_child(left_wall)
		# Right segment
		var right_wall = create_textured_structure(segment_size, Vector3(pos.x + entrance_width/2 + segment_size.x/2, pos.y, pos.z), "wall")
		wall_section.add_child(right_wall)
	else:
		segment_size.z = (size.z - entrance_width) / 2
		# Front segment
		var front_wall = create_textured_structure(segment_size, Vector3(pos.x, pos.y, pos.z - entrance_width/2 - segment_size.z/2), "wall")
		wall_section.add_child(front_wall)
		# Back segment
		var back_wall = create_textured_structure(segment_size, Vector3(pos.x, pos.y, pos.z + entrance_width/2 + segment_size.z/2), "wall")
		wall_section.add_child(back_wall)

func create_central_compound_with_openings():
	var compound = Node3D.new()
	compound.name = "Central_Compound"
	add_child(compound)
	
	# Main building with proper rooms and openings
	var main_building = create_building_with_real_openings(Vector3(0, 0, 0), Vector3(50, 15, 35), 3)
	main_building.name = "Main_Building"
	compound.add_child(main_building)
	
	strategic_positions.append(Vector3(0, 15, 0))

func create_building_with_real_openings(pos: Vector3, size: Vector3, floors: int) -> Node3D:
	var building = Node3D.new()
	building.name = "Building_With_Openings"
	
	for floor in range(floors):
		var floor_y = pos.y + (floor * 5)
		create_floor_with_rooms(building, pos, size, floor_y, floor)
	
	# Create external ramps for each floor
	for floor in range(floors):
		create_external_ramp_to_floor(building, pos, size, floor)
	
	return building

func create_floor_with_rooms(parent: Node3D, base_pos: Vector3, size: Vector3, floor_y: float, floor_num: int):
	var floor_container = Node3D.new()
	floor_container.name = "Floor_" + str(floor_num)
	parent.add_child(floor_container)
	
	# Floor slab
	var floor_slab = create_textured_structure(Vector3(size.x, 0.5, size.z), Vector3(base_pos.x, floor_y, base_pos.z), "floor")
	floor_slab.name = "Floor_Slab"
	floor_container.add_child(floor_slab)
	
	# Outer walls with windows
	create_outer_walls_with_windows(floor_container, base_pos, size, floor_y)
	
	# Interior walls with doors
	create_interior_walls_with_doors(floor_container, base_pos, size, floor_y)
	
	# Interior stairs/ramps
	if floor_num < 2:  # Don't create stairs on top floor
		create_interior_staircase(floor_container, base_pos, size, floor_y)

func create_outer_walls_with_windows(parent: Node3D, base_pos: Vector3, size: Vector3, floor_y: float):
	var wall_height = 4
	var window_width = 6
	var window_height = 2
	
	# North wall with windows
	create_wall_with_windows(parent, 
		Vector3(base_pos.x, floor_y + wall_height/2, base_pos.z + size.z/2), 
		Vector3(size.x, wall_height, 1), 
		"North", window_width, window_height)
	
	# South wall with windows
	create_wall_with_windows(parent, 
		Vector3(base_pos.x, floor_y + wall_height/2, base_pos.z - size.z/2), 
		Vector3(size.x, wall_height, 1), 
		"South", window_width, window_height)
	
	# East wall with windows
	create_wall_with_windows(parent, 
		Vector3(base_pos.x + size.x/2, floor_y + wall_height/2, base_pos.z), 
		Vector3(1, wall_height, size.z), 
		"East", window_width, window_height)
	
	# West wall with windows
	create_wall_with_windows(parent, 
		Vector3(base_pos.x - size.x/2, floor_y + wall_height/2, base_pos.z), 
		Vector3(1, wall_height, size.z), 
		"West", window_width, window_height)

func create_wall_with_windows(parent: Node3D, pos: Vector3, size: Vector3, direction: String, window_width: float, window_height: float):
	var wall_container = Node3D.new()
	wall_container.name = "Wall_" + direction + "_With_Windows"
	parent.add_child(wall_container)
	
	# Determine main axis
	var is_horizontal = size.x > size.z
	var main_length = size.x if is_horizontal else size.z
	
	# Calculate window positions
	var num_windows = floor(main_length / (window_width + 4))  # 4 units between windows
	var window_spacing = main_length / (num_windows + 1)
	
	for i in range(num_windows):
		var window_offset = (i - (num_windows - 1) / 2.0) * window_spacing
		var window_pos = pos
		
		if is_horizontal:
			window_pos.x += window_offset
		else:
			window_pos.z += window_offset
		
		# Create window opening
		create_window_opening(wall_container, window_pos, window_width, window_height, direction)
	
	# Create wall segments between windows
	create_wall_segments_between_openings(wall_container, pos, size, num_windows, window_width, window_spacing, is_horizontal)

func create_window_opening(parent: Node3D, pos: Vector3, width: float, height: float, direction: String):
	# Window frame
	var frame = create_textured_structure(Vector3(width + 0.2, height + 0.2, 0.1), pos, "metal")
	frame.name = "Window_Frame"
	parent.add_child(frame)
	
	# Glass pane (optional visual)
	var glass = create_textured_structure(Vector3(width, height, 0.05), pos, "glass")
	glass.name = "Window_Glass"
	parent.add_child(glass)

func create_wall_segments_between_openings(parent: Node3D, pos: Vector3, size: Vector3, num_windows: int, window_width: float, window_spacing: float, is_horizontal: bool):
	# Create wall segments between and around windows
	var segment_count = num_windows + 1
	var segment_width = window_spacing - window_width
	
	for i in range(segment_count):
		var segment_offset = (i - segment_count / 2.0 + 0.5) * window_spacing
		var segment_pos = pos
		var segment_size = size
		
		if is_horizontal:
			segment_pos.x += segment_offset
			segment_size.x = segment_width
		else:
			segment_pos.z += segment_offset
			segment_size.z = segment_width
		
		if segment_width > 0.5:  # Only create if segment is wide enough
			var segment = create_textured_structure(segment_size, segment_pos, "wall")
			segment.name = "Wall_Segment_" + str(i)
			parent.add_child(segment)

func create_interior_walls_with_doors(parent: Node3D, base_pos: Vector3, size: Vector3, floor_y: float):
	var wall_height = 4
	var door_width = 3
	var door_height = 3
	
	# Central dividing wall (North-South) with door
	var ns_wall_pos = Vector3(base_pos.x, floor_y + wall_height/2, base_pos.z)
	create_wall_with_door(parent, ns_wall_pos, Vector3(1, wall_height, size.z * 0.8), door_width, door_height, "NS_Divider")
	
	# Central dividing wall (East-West) with door
	var ew_wall_pos = Vector3(base_pos.x, floor_y + wall_height/2, base_pos.z)
	create_wall_with_door(parent, ew_wall_pos, Vector3(size.x * 0.8, wall_height, 1), door_width, door_height, "EW_Divider")

func create_wall_with_door(parent: Node3D, pos: Vector3, size: Vector3, door_width: float, door_height: float, wall_name: String):
	var wall_container = Node3D.new()
	wall_container.name = wall_name + "_With_Door"
	parent.add_child(wall_container)
	
	# Determine orientation
	var is_horizontal = size.x > size.z
	var main_length = size.x if is_horizontal else size.z
	
	# Create wall segments on either side of door
	var segment_length = (main_length - door_width) / 2
	
	if is_horizontal:
		# Left segment
		var left_wall = create_textured_structure(
			Vector3(segment_length, size.y, size.z), 
			Vector3(pos.x - door_width/2 - segment_length/2, pos.y, pos.z), 
			"wall"
		)
		left_wall.name = "Left_Wall_Segment"
		wall_container.add_child(left_wall)
		
		# Right segment
		var right_wall = create_textured_structure(
			Vector3(segment_length, size.y, size.z), 
			Vector3(pos.x + door_width/2 + segment_length/2, pos.y, pos.z), 
			"wall"
		)
		right_wall.name = "Right_Wall_Segment"
		wall_container.add_child(right_wall)
	else:
		# Front segment
		var front_wall = create_textured_structure(
			Vector3(size.x, size.y, segment_length), 
			Vector3(pos.x, pos.y, pos.z - door_width/2 - segment_length/2), 
			"wall"
		)
		front_wall.name = "Front_Wall_Segment"
		wall_container.add_child(front_wall)
		
		# Back segment
		var back_wall = create_textured_structure(
			Vector3(size.x, size.y, segment_length), 
			Vector3(pos.x, pos.y, pos.z + door_width/2 + segment_length/2), 
			"wall"
		)
		back_wall.name = "Back_Wall_Segment"
		wall_container.add_child(back_wall)
	
	# Door frame
	var door_frame = create_textured_structure(
		Vector3(door_width + 0.2, door_height + 0.2, 0.2), 
		Vector3(pos.x, pos.y - (size.y - door_height)/2, pos.z), 
		"metal"
	)
	door_frame.name = "Door_Frame"
	wall_container.add_child(door_frame)

func create_interior_staircase(parent: Node3D, base_pos: Vector3, size: Vector3, floor_y: float):
	# Interior staircase/ramp
	var stair_container = Node3D.new()
	stair_container.name = "Interior_Staircase"
	parent.add_child(stair_container)
	
	var stair_width = 4
	var stair_length = 10
	var stair_height = 5
	
	# Create angled ramp for stairs
	var ramp = create_textured_structure(
		Vector3(stair_width, 0.5, stair_length), 
		Vector3(base_pos.x + size.x/3, floor_y + stair_height/2, base_pos.z), 
		"ramp"
	)
	ramp.name = "Stair_Ramp"
	stair_container.add_child(ramp)
	
	# Stair railings
	var left_rail = create_textured_structure(
		Vector3(0.2, 2, stair_length), 
		Vector3(base_pos.x + size.x/3 - stair_width/2, floor_y + stair_height/2 + 1, base_pos.z), 
		"metal"
	)
	left_rail.name = "Left_Railing"
	stair_container.add_child(left_rail)
	
	var right_rail = create_textured_structure(
		Vector3(0.2, 2, stair_length), 
		Vector3(base_pos.x + size.x/3 + stair_width/2, floor_y + stair_height/2 + 1, base_pos.z), 
		"metal"
	)
	right_rail.name = "Right_Railing"
	stair_container.add_child(right_rail)

func create_external_ramp_to_floor(parent: Node3D, base_pos: Vector3, size: Vector3, floor: int):
	if floor == 0:
		return  # No ramp needed for ground floor
	
	var ramp_container = Node3D.new()
	ramp_container.name = "External_Ramp_Floor_" + str(floor)
	parent.add_child(ramp_container)
	
	var ramp_width = 6
	var ramp_length = 20
	var target_height = floor * 5
	
	# Position ramp on different sides for each floor
	var ramp_positions = [
		Vector3(base_pos.x + size.x/2 + ramp_length/2, target_height/2, base_pos.z),  # East
		Vector3(base_pos.x - size.x/2 - ramp_length/2, target_height/2, base_pos.z),  # West
		Vector3(base_pos.x, target_height/2, base_pos.z + size.z/2 + ramp_length/2),  # North
		Vector3(base_pos.x, target_height/2, base_pos.z - size.z/2 - ramp_length/2)   # South
	]
	
	var ramp_pos = ramp_positions[floor % 4]
	
	# Create ramp structure
	var ramp = create_textured_structure(
		Vector3(ramp_width, 1, ramp_length), 
		ramp_pos, 
		"ramp"
	)
	ramp.name = "Ramp_Structure"
	ramp_container.add_child(ramp)
	
	# Ramp supports
	var support_count = 4
	for i in range(support_count):
		var support_pos = ramp_pos + Vector3(0, -target_height/2 - 1, (i - support_count/2.0) * ramp_length/support_count)
		var support = create_textured_structure(
			Vector3(1, target_height, 1), 
			support_pos, 
			"metal"
		)
		support.name = "Ramp_Support_" + str(i)
		ramp_container.add_child(support)

func create_multi_level_buildings():
	var buildings_container = Node3D.new()
	buildings_container.name = "Multi_Level_Buildings"
	add_child(buildings_container)
	
	var building_positions = [
		Vector3(-80, 0, 60),
		Vector3(80, 0, 60),
		Vector3(-80, 0, -60),
		Vector3(80, 0, -60)
	]
	
	for i in range(building_positions.size()):
		var building = create_building_with_real_openings(building_positions[i], Vector3(30, 12, 25), 2)
		building.name = "Multi_Level_Building_" + str(i)
		buildings_container.add_child(building)
		strategic_positions.append(building_positions[i] + Vector3(0, 12, 0))

func create_spawn_facilities_with_doors():
	var spawn_container = Node3D.new()
	spawn_container.name = "Spawn_Facilities"
	add_child(spawn_container)
	
	var spawn_distance = arena_size.x * 0.4
	var spawn_positions = [
		Vector3(-spawn_distance, 0, -spawn_distance),
		Vector3(spawn_distance, 0, -spawn_distance),
		Vector3(-spawn_distance, 0, spawn_distance),
		Vector3(spawn_distance, 0, spawn_distance)
	]
	
	for i in range(spawn_positions.size()):
		var spawn_facility = create_spawn_facility_with_doors(spawn_positions[i], i)
		spawn_container.add_child(spawn_facility)
		spawn_points.append(spawn_positions[i])

func create_spawn_facility_with_doors(pos: Vector3, index: int) -> Node3D:
	var facility = Node3D.new()
	facility.name = "Spawn_Facility_" + str(index)
	
	# Main spawn room structure
	var room_size = Vector3(25, 6, 20)
	var room_container = Node3D.new()
	room_container.name = "Spawn_Room"
	facility.add_child(room_container)
	
	# Floor
	var floor = create_textured_structure(Vector3(room_size.x, 0.5, room_size.z), pos, "spawn")
	floor.name = "Spawn_Floor"
	room_container.add_child(floor)
	
	# Walls with doors
	create_spawn_room_walls_with_doors(room_container, pos, room_size)
	
	# Weapon spawn inside
	var weapon_spawn = create_weapon_spawn_point(pos)
	facility.add_child(weapon_spawn)
	
	return facility

func create_spawn_room_walls_with_doors(parent: Node3D, pos: Vector3, size: Vector3):
	var wall_height = 5
	var door_width = 4
	var door_height = 4
	
	# Create walls with doors on 3 sides (leave one side open)
	var wall_configs = [
		{"pos": Vector3(pos.x, pos.y + wall_height/2, pos.z + size.z/2), "size": Vector3(size.x, wall_height, 1), "name": "North"},
		{"pos": Vector3(pos.x + size.x/2, pos.y + wall_height/2, pos.z), "size": Vector3(1, wall_height, size.z), "name": "East"},
		{"pos": Vector3(pos.x - size.x/2, pos.y + wall_height/2, pos.z), "size": Vector3(1, wall_height, size.z), "name": "West"}
	]
	
	for config in wall_configs:
		create_wall_with_door(parent, config["pos"], config["size"], door_width, door_height, config["name"])

func create_sniper_towers_with_access():
	var towers_container = Node3D.new()
	towers_container.name = "Sniper_Towers"
	add_child(towers_container)
	
	var tower_positions = [
		Vector3(-100, 0, 100),
		Vector3(100, 0, 100),
		Vector3(-100, 0, -100),
		Vector3(100, 0, -100)
	]
	
	for i in range(tower_positions.size()):
		var tower = create_sniper_tower_with_access(tower_positions[i])
		tower.name = "Sniper_Tower_" + str(i)
		towers_container.add_child(tower)
		strategic_positions.append(tower_positions[i] + Vector3(0, 15, 0))

func create_sniper_tower_with_access(pos: Vector3) -> Node3D:
	var tower = Node3D.new()
	tower.name = "Sniper_Tower"
	
	# Tower base
	var base_size = Vector3(10, 15, 10)
	var base = create_textured_structure(base_size, pos + Vector3(0, base_size.y/2, 0), "wall")
	base.name = "Tower_Base"
	tower.add_child(base)
	
	# Sniper platform
	var platform_size = Vector3(15, 2, 15)
	var platform = create_textured_structure(platform_size, pos + Vector3(0, base_size.y + platform_size.y/2, 0), "strategic")
	platform.name = "Sniper_Platform"
	tower.add_child(platform)
	
	# External spiral ramp
	create_spiral_ramp(tower, pos, base_size.y)
	
	# Protective barriers with shooting windows
	create_sniper_barriers_with_windows(tower, pos + Vector3(0, base_size.y + platform_size.y/2, 0))
	
	return tower

func create_spiral_ramp(parent: Node3D, base_pos: Vector3, height: float):
	var ramp_container = Node3D.new()
	ramp_container.name = "Spiral_Ramp"
	parent.add_child(ramp_container)
	
	var ramp_segments = 8
	var radius = 12
	var segment_height = height / ramp_segments
	
	for i in range(ramp_segments):
		var angle = (i * TAU) / ramp_segments
		var ramp_pos = base_pos + Vector3(cos(angle) * radius, i * segment_height + segment_height/2, sin(angle) * radius)
		
		var ramp_segment = create_textured_structure(
			Vector3(4, 1, 8), 
			ramp_pos, 
			"ramp"
		)
		ramp_segment.name = "Ramp_Segment_" + str(i)
		ramp_container.add_child(ramp_segment)

func create_sniper_barriers_with_windows(parent: Node3D, pos: Vector3):
	var barrier_positions = [
		Vector3(pos.x + 7, pos.y + 2, pos.z),
		Vector3(pos.x - 7, pos.y + 2, pos.z),
		Vector3(pos.x, pos.y + 2, pos.z + 7),
		Vector3(pos.x, pos.y + 2, pos.z - 7)
	]
	
	for i in range(barrier_positions.size()):
		var barrier_container = Node3D.new()
		barrier_container.name = "Sniper_Barrier_" + str(i)
		parent.add_child(barrier_container)
		
		# Barrier with shooting window
		var barrier_size = Vector3(1, 3, 6)
		var window_size = Vector3(1.1, 0.8, 2)
		
		# Create barrier segments around window
		var segments = [
			Vector3(barrier_positions[i].x, barrier_positions[i].y - 1, barrier_positions[i].z - 2),
			Vector3(barrier_positions[i].x, barrier_positions[i].y - 1, barrier_positions[i].z + 2),
			Vector3(barrier_positions[i].x, barrier_positions[i].y + 1, barrier_positions[i].z)
		]
		
		for j in range(segments.size()):
			var segment_size = Vector3(1, 1, 2) if j < 2 else Vector3(1, 1, 6)
			var segment = create_textured_structure(segment_size, segments[j], "cover")
			segment.name = "Barrier_Segment_" + str(j)
			barrier_container.add_child(segment)

func create_connecting_walkways():
	var walkways_container = Node3D.new()
	walkways_container.name = "Connecting_Walkways"
	add_child(walkways_container)
	
	# High-level walkways between buildings
	var walkway_configs = [
		{"from": Vector3(-80, 10, 60), "to": Vector3(80, 10, 60), "name": "North_Walkway"},
		{"from": Vector3(-80, 10, -60), "to": Vector3(80, 10, -60), "name": "South_Walkway"},
		{"from": Vector3(-80, 8, 60), "to": Vector3(-80, 8, -60), "name": "West_Walkway"},
		{"from": Vector3(80, 8, 60), "to": Vector3(80, 8, -60), "name": "East_Walkway"}
	]
	
	for config in walkway_configs:
		create_walkway_bridge(walkways_container, config["from"], config["to"], config["name"])

func create_walkway_bridge(parent: Node3D, from_pos: Vector3, to_pos: Vector3, name: String):
	var bridge_container = Node3D.new()
	bridge_container.name = name
	parent.add_child(bridge_container)
	
	var bridge_center = (from_pos + to_pos) / 2
	var bridge_length = from_pos.distance_to(to_pos)
	var bridge_width = 4
	
	# Bridge deck
	var bridge_deck = create_textured_structure(
		Vector3(bridge_width, 0.5, bridge_length), 
		bridge_center, 
		"metal"
	)
	bridge_deck.name = "Bridge_Deck"
	bridge_container.add_child(bridge_deck)
	
	# Bridge railings
	var left_rail = create_textured_structure(
		Vector3(0.2, 2, bridge_length), 
		bridge_center + Vector3(-bridge_width/2, 1, 0), 
		"metal"
	)
	left_rail.name = "Left_Railing"
	bridge_container.add_child(left_rail)
	
	var right_rail = create_textured_structure(
		Vector3(0.2, 2, bridge_length), 
		bridge_center + Vector3(bridge_width/2, 1, 0), 
		"metal"
	)
	right_rail.name = "Right_Railing"
	bridge_container.add_child(right_rail)
	
	# Bridge supports
	var support_count = max(3, int(bridge_length / 20))
	for i in range(support_count):
		var support_pos = bridge_center + Vector3(0, -bridge_center.y/2, (i - support_count/2.0) * bridge_length/support_count)
		var support = create_textured_structure(
			Vector3(1, bridge_center.y, 1), 
			support_pos, 
			"metal"
		)
		support.name = "Bridge_Support_" + str(i)
		bridge_container.add_child(support)

func create_tactical_ramp_system():
	var ramp_container = Node3D.new()
	ramp_container.name = "Tactical_Ramp_System"
	add_child(ramp_container)
	
	# Various ramps for tactical movement
	var ramp_configs = [
		{"pos": Vector3(-40, 0, 0), "size": Vector3(8, 1, 20), "height": 5, "name": "West_Tactical_Ramp"},
		{"pos": Vector3(40, 0, 0), "size": Vector3(8, 1, 20), "height": 5, "name": "East_Tactical_Ramp"},
		{"pos": Vector3(0, 0, -40), "size": Vector3(20, 1, 8), "height": 5, "name": "South_Tactical_Ramp"},
		{"pos": Vector3(0, 0, 40), "size": Vector3(20, 1, 8), "height": 5, "name": "North_Tactical_Ramp"}
	]
	
	for config in ramp_configs:
		create_tactical_ramp(ramp_container, config["pos"], config["size"], config["height"], config["name"])

func create_tactical_ramp(parent: Node3D, pos: Vector3, size: Vector3, height: float, name: String):
	var ramp_structure = Node3D.new()
	ramp_structure.name = name
	parent.add_child(ramp_structure)
	
	# Main ramp
	var ramp = create_textured_structure(size, pos + Vector3(0, height/2, 0), "ramp")
	ramp.name = "Ramp_Surface"
	ramp_structure.add_child(ramp)
	
	# Ramp sides/supports
	var supports = [
		Vector3(pos.x - size.x/2, pos.y + height/4, pos.z),
		Vector3(pos.x + size.x/2, pos.y + height/4, pos.z),
		Vector3(pos.x, pos.y + height/4, pos.z - size.z/2),
		Vector3(pos.x, pos.y + height/4, pos.z + size.z/2)
	]
	
	for i in range(supports.size()):
		var support = create_textured_structure(
			Vector3(1, height/2, 1), 
			supports[i], 
			"metal"
		)
		support.name = "Ramp_Support_" + str(i)
		ramp_structure.add_child(support)

func create_weapon_rooms_with_entrances():
	var weapon_container = Node3D.new()
	weapon_container.name = "Weapon_Rooms"
	add_child(weapon_container)
	
	var weapon_positions = [
		Vector3(-60, 0, 0),    # Shotgun room
		Vector3(60, 0, 0),     # Rifle room
		Vector3(0, 0, -60),    # Sniper room
		Vector3(0, 0, 60),     # Heavy weapons room
		Vector3(-30, 0, 30),   # SMG room
		Vector3(30, 0, -30)    # Explosive room
	]
	
	for i in range(weapon_positions.size()):
		var weapon_room = create_weapon_room_with_entrance(weapon_positions[i], i)
		weapon_container.add_child(weapon_room)

func create_weapon_room_with_entrance(pos: Vector3, index: int) -> Node3D:
	var room = Node3D.new()
	room.name = "Weapon_Room_" + str(index)
	
	var room_size = Vector3(15, 6, 12)
	
	# Room floor
	var floor = create_textured_structure(Vector3(room_size.x, 0.5, room_size.z), pos, "weapon")
	floor.name = "Weapon_Room_Floor"
	room.add_child(floor)
	
	# Room walls with entrance
	create_weapon_room_walls_with_entrance(room, pos, room_size)
	
	# Central weapon spawn
	var weapon_spawn = create_weapon_spawn_point(pos + Vector3(0, 1, 0))
	room.add_child(weapon_spawn)
	
	# Ammo crates
	var ammo_positions = [
		Vector3(pos.x - 5, pos.y + 0.5, pos.z - 3),
		Vector3(pos.x + 5, pos.y + 0.5, pos.z - 3),
		Vector3(pos.x - 5, pos.y + 0.5, pos.z + 3),
		Vector3(pos.x + 5, pos.y + 0.5, pos.z + 3)
	]
	
	for i in range(ammo_positions.size()):
		var ammo_crate = create_textured_structure(
			Vector3(2, 1, 2), 
			ammo_positions[i], 
			"cover"
		)
		ammo_crate.name = "Ammo_Crate_" + str(i)
		room.add_child(ammo_crate)
	
	return room

func create_weapon_room_walls_with_entrance(parent: Node3D, pos: Vector3, size: Vector3):
	var wall_height = 5
	var entrance_width = 6
	
	# Create walls with one entrance
	var wall_configs = [
		{"pos": Vector3(pos.x, pos.y + wall_height/2, pos.z + size.z/2), "size": Vector3(size.x, wall_height, 1), "entrance": true},
		{"pos": Vector3(pos.x, pos.y + wall_height/2, pos.z - size.z/2), "size": Vector3(size.x, wall_height, 1), "entrance": false},
		{"pos": Vector3(pos.x + size.x/2, pos.y + wall_height/2, pos.z), "size": Vector3(1, wall_height, size.z), "entrance": false},
		{"pos": Vector3(pos.x - size.x/2, pos.y + wall_height/2, pos.z), "size": Vector3(1, wall_height, size.z), "entrance": false}
	]
	
	for i in range(wall_configs.size()):
		var config = wall_configs[i]
		if config["entrance"]:
			create_wall_with_entrance_opening(parent, config["pos"], config["size"], entrance_width, "Wall_" + str(i))
		else:
			var wall = create_textured_structure(config["size"], config["pos"], "wall")
			wall.name = "Wall_" + str(i)
			parent.add_child(wall)

func create_wall_with_entrance_opening(parent: Node3D, pos: Vector3, size: Vector3, entrance_width: float, name: String):
	var wall_container = Node3D.new()
	wall_container.name = name + "_With_Entrance"
	parent.add_child(wall_container)
	
	var is_horizontal = size.x > size.z
	var remaining_width = (size.x - entrance_width) if is_horizontal else (size.z - entrance_width)
	var segment_width = remaining_width / 2
	
	if is_horizontal:
		# Left segment
		var left_wall = create_textured_structure(
			Vector3(segment_width, size.y, size.z), 
			Vector3(pos.x - entrance_width/2 - segment_width/2, pos.y, pos.z), 
			"wall"
		)
		left_wall.name = "Left_Wall_Segment"
		wall_container.add_child(left_wall)
		
		# Right segment
		var right_wall = create_textured_structure(
			Vector3(segment_width, size.y, size.z), 
			Vector3(pos.x + entrance_width/2 + segment_width/2, pos.y, pos.z), 
			"wall"
		)
		right_wall.name = "Right_Wall_Segment"
		wall_container.add_child(right_wall)
	else:
		# Front segment
		var front_wall = create_textured_structure(
			Vector3(size.x, size.y, segment_width), 
			Vector3(pos.x, pos.y, pos.z - entrance_width/2 - segment_width/2), 
			"wall"
		)
		front_wall.name = "Front_Wall_Segment"
		wall_container.add_child(front_wall)
		
		# Back segment
		var back_wall = create_textured_structure(
			Vector3(size.x, size.y, segment_width), 
			Vector3(pos.x, pos.y, pos.z + entrance_width/2 + segment_width/2), 
			"wall"
		)
		back_wall.name = "Back_Wall_Segment"
		wall_container.add_child(back_wall)

func create_weapon_spawn_point(pos: Vector3) -> MeshInstance3D:
	var weapon_marker = MeshInstance3D.new()
	weapon_marker.name = "Weapon_Spawn_Point"
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 0.5
	cylinder_mesh.top_radius = 1.5
	cylinder_mesh.bottom_radius = 1.5
	
	weapon_marker.mesh = cylinder_mesh
	weapon_marker.position = pos
	weapon_marker.material_override = materials["weapon"]
	
	weapon_spawn_points.append(pos)
	return weapon_marker

func create_advanced_cover_system():
	var cover_container = Node3D.new()
	cover_container.name = "Advanced_Cover_System"
	add_child(cover_container)
	
	# Strategic cover placement
	var cover_clusters = [
		Vector3(-45, 0, -45),
		Vector3(45, 0, -45),
		Vector3(-45, 0, 45),
		Vector3(45, 0, 45),
		Vector3(-20, 0, 0),
		Vector3(20, 0, 0),
		Vector3(0, 0, -20),
		Vector3(0, 0, 20)
	]
	
	for i in range(cover_clusters.size()):
		create_advanced_cover_cluster(cover_container, cover_clusters[i], i)

func create_advanced_cover_cluster(parent: Node3D, center: Vector3, index: int):
	var cluster = Node3D.new()
	cluster.name = "Advanced_Cover_Cluster_" + str(index)
	parent.add_child(cluster)
	
	var cover_types = [
		{"size": Vector3(5, 1.5, 1), "name": "Low_Wall", "material": "cover"},
		{"size": Vector3(2, 3, 2), "name": "Column", "material": "cover"},
		{"size": Vector3(4, 2, 4), "name": "Crate", "material": "cover"},
		{"size": Vector3(1, 2.5, 5), "name": "Barrier", "material": "cover"},
		{"size": Vector3(3, 1, 3), "name": "Platform", "material": "metal"}
	]
	
	var cover_count = randi_range(5, 8)
	for i in range(cover_count):
		var angle = (i * TAU) / cover_count + randf_range(-0.4, 0.4)
		var distance = randf_range(6, 15)
		var cover_pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		var cover_type = cover_types[randi() % cover_types.size()]
		var cover = create_textured_structure(
			cover_type["size"],
			cover_pos + Vector3(0, cover_type["size"].y / 2, 0),
			cover_type["material"]
		)
		cover.name = cover_type["name"] + "_" + str(i)
		cluster.add_child(cover)
		cover_positions.append(cover_pos)

func create_choke_points_with_passages():
	var choke_container = Node3D.new()
	choke_container.name = "Choke_Points_With_Passages"
	add_child(choke_container)
	
	var choke_positions = [
		Vector3(0, 0, -110),   # South passage
		Vector3(0, 0, 110),    # North passage
		Vector3(-110, 0, 0),   # West passage
		Vector3(110, 0, 0)     # East passage
	]
	
	for i in range(choke_positions.size()):
		var choke = create_choke_point_with_passage(choke_positions[i])
		choke.name = "Choke_Point_" + str(i)
		choke_container.add_child(choke)

func create_choke_point_with_passage(pos: Vector3) -> Node3D:
	var choke = Node3D.new()
	choke.name = "Choke_Point_With_Passage"
	
	var is_horizontal = abs(pos.x) > abs(pos.z)
	var corridor_width = 10
	var corridor_length = 30
	var wall_height = 6
	
	if is_horizontal:
		# East-West corridor
		var wall1 = create_textured_structure(
			Vector3(corridor_length, wall_height, 2),
			pos + Vector3(0, wall_height/2, corridor_width/2 + 1),
			"wall"
		)
		wall1.name = "North_Wall"
		choke.add_child(wall1)
		
		var wall2 = create_textured_structure(
			Vector3(corridor_length, wall_height, 2),
			pos + Vector3(0, wall_height/2, -corridor_width/2 - 1),
			"wall"
		)
		wall2.name = "South_Wall"
		choke.add_child(wall2)
		
		# Cover inside corridor
		var cover = create_textured_structure(
			Vector3(4, 2, 4),
			pos + Vector3(0, 1, 0),
			"cover"
		)
		cover.name = "Corridor_Cover"
		choke.add_child(cover)
		
	else:
		# North-South corridor
		var wall1 = create_textured_structure(
			Vector3(2, wall_height, corridor_length),
			pos + Vector3(corridor_width/2 + 1, wall_height/2, 0),
			"wall"
		)
		wall1.name = "East_Wall"
		choke.add_child(wall1)
		
		var wall2 = create_textured_structure(
			Vector3(2, wall_height, corridor_length),
			pos + Vector3(-corridor_width/2 - 1, wall_height/2, 0),
			"wall"
		)
		wall2.name = "West_Wall"
		choke.add_child(wall2)
		
		# Cover inside corridor
		var cover = create_textured_structure(
			Vector3(4, 2, 4),
			pos + Vector3(0, 1, 0),
			"cover"
		)
		cover.name = "Corridor_Cover"
		choke.add_child(cover)
	
	return choke

func create_underground_with_access():
	var underground = Node3D.new()
	underground.name = "Underground_System"
	add_child(underground)
	
	# Underground tunnels
	var tunnel_height = 4
	var tunnel_width = 10
	
	# Main tunnel (East-West)
	var main_tunnel = create_textured_structure(
		Vector3(arena_size.x * 0.8, tunnel_height, tunnel_width),
		Vector3(0, -tunnel_height/2 - 1, 0),
		"wall"
	)
	main_tunnel.name = "Main_Underground_Tunnel"
	underground.add_child(main_tunnel)
	
	# Cross tunnel (North-South)
	var cross_tunnel = create_textured_structure(
		Vector3(tunnel_width, tunnel_height, arena_size.z * 0.8),
		Vector3(0, -tunnel_height/2 - 1, 0),
		"wall"
	)
	cross_tunnel.name = "Cross_Underground_Tunnel"
	underground.add_child(cross_tunnel)
	
	# Access points with stairs
	var access_points = [
		Vector3(-80, 0, 0),
		Vector3(80, 0, 0),
		Vector3(0, 0, -80),
		Vector3(0, 0, 80)
	]
	
	for i in range(access_points.size()):
		create_underground_access_point(underground, access_points[i], i)

func create_underground_access_point(parent: Node3D, pos: Vector3, index: int):
	var access = Node3D.new()
	access.name = "Underground_Access_" + str(index)
	parent.add_child(access)
	
	# Access structure
	var access_structure = create_textured_structure(
		Vector3(8, 6, 8),
		pos + Vector3(0, 3, 0),
		"metal"
	)
	access_structure.name = "Access_Structure"
	access.add_child(access_structure)
	
	# Stairs down
	var stair_segments = 5
	for i in range(stair_segments):
		var stair_y = pos.y - i * 1.2
		var stair = create_textured_structure(
			Vector3(6, 0.5, 6),
			Vector3(pos.x, stair_y, pos.z),
			"ramp"
		)
		stair.name = "Stair_Segment_" + str(i)
		access.add_child(stair)

func create_special_areas_and_details():
	var special_container = Node3D.new()
	special_container.name = "Special_Areas"
	add_child(special_container)
	
	# Health stations
	var health_positions = [
		Vector3(0, 0, -130),
		Vector3(0, 0, 130),
		Vector3(-130, 0, 0),
		Vector3(130, 0, 0)
	]
	
	for i in range(health_positions.size()):
		var health_station = create_special_station(health_positions[i], "Health_Station_" + str(i), "strategic")
		special_container.add_child(health_station)
	
	# Power-up pedestals
	var powerup_positions = [
		Vector3(-50, 0, -50),
		Vector3(50, 0, -50),
		Vector3(-50, 0, 50),
		Vector3(50, 0, 50)
	]
	
	for i in range(powerup_positions.size()):
		var powerup = create_powerup_pedestal(powerup_positions[i])
		powerup.name = "Powerup_Pedestal_" + str(i)
		special_container.add_child(powerup)

func create_special_station(pos: Vector3, name: String, material: String) -> Node3D:
	var station = Node3D.new()
	station.name = name
	
	var base = create_textured_structure(Vector3(6, 1, 6), pos + Vector3(0, 0.5, 0), material)
	base.name = "Station_Base"
	station.add_child(base)
	
	var console = create_textured_structure(Vector3(2, 2, 2), pos + Vector3(0, 2, 0), "metal")
	console.name = "Station_Console"
	station.add_child(console)
	
	return station

func create_powerup_pedestal(pos: Vector3) -> Node3D:
	var pedestal = Node3D.new()
	pedestal.name = "Powerup_Pedestal"
	
	var base = create_textured_structure(Vector3(3, 1, 3), pos + Vector3(0, 0.5, 0), "metal")
	base.name = "Pedestal_Base"
	pedestal.add_child(base)
	
	var top = create_textured_structure(Vector3(2, 0.5, 2), pos + Vector3(0, 1.5, 0), "strategic")
	top.name = "Pedestal_Top"
	pedestal.add_child(top)
	
	return pedestal

func create_textured_structure(size: Vector3, pos: Vector3, material_key: String) -> StaticBody3D:
	var structure = StaticBody3D.new()
	structure.name = "Structure"
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.material_override = materials[material_key]
	
	var collision = CollisionShape3D.new()
	collision.name = "Collision"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	
	mesh_instance.mesh = box_mesh
	mesh_instance.position = pos
	
	collision.shape = box_mesh.create_trimesh_shape()
	collision.position = pos
	
	structure.add_child(mesh_instance)
	structure.add_child(collision)
	
	return structure

func create_navigation_system():
	var nav_region = NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.1
	nav_mesh.agent_radius = 0.6
	nav_mesh.agent_height = 1.8
	nav_mesh.region_min_size = 4
	nav_mesh.agent_max_climb = 1.5  # Can climb stairs/ramps
	nav_mesh.agent_max_slope = 45.0
	
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)
	
	print("🧭 Advanced Navigation System Created!")

func setup_lighting():
	# Directional sunlight
	var sun_light = DirectionalLight3D.new()
	sun_light.name = "Sun_Light"
	sun_light.light_energy = 0.8
	sun_light.position = Vector3(0, 50, 0)
	sun_light.rotation_degrees = Vector3(-45, 30, 0)
	sun_light.shadow_enabled = true
	add_child(sun_light)
	
	# Point lights at key locations
	var light_positions = [
		Vector3(0, 12, 0),      # Central compound
		Vector3(-80, 10, 60),   # Northwest building
		Vector3(80, 10, 60),    # Northeast building
		Vector3(-80, 10, -60),  # Southwest building
		Vector3(80, 10, -60),   # Southeast building
		Vector3(0, 8, 0),       # Underground access
		Vector3(-100, 18, 100), # Sniper tower
		Vector3(100, 18, 100),  # Sniper tower
		Vector3(-100, 18, -100), # Sniper tower
		Vector3(100, 18, -100)  # Sniper tower
	]
	
	for i in range(light_positions.size()):
		var point_light = OmniLight3D.new()
		point_light.name = "Strategic_Light_" + str(i)
		point_light.light_energy = 0.6
		point_light.omni_range = 25
		point_light.position = light_positions[i]
		point_light.light_color = Color(1.0, 0.95, 0.8)
		add_child(point_light)

func add_debug_markers():
	if not enable_debug_markers:
		return
		
	var debug_container = Node3D.new()
	debug_container.name = "Debug_Markers"
	add_child(debug_container)
	
	# Spawn points (Green spheres)
	for i in range(spawn_points.size()):
		var marker = create_debug_marker(spawn_points[i], Color.GREEN, "SPAWN_" + str(i))
		debug_container.add_child(marker)
	
	# Strategic positions (Blue spheres)
	for i in range(strategic_positions.size()):
		var marker = create_debug_marker(strategic_positions[i], Color.BLUE, "STRATEGIC_" + str(i))
		debug_container.add_child(marker)
	
	# Weapon spawns (Red spheres)
	for i in range(weapon_spawn_points.size()):
		var marker = create_debug_marker(weapon_spawn_points[i], Color.RED, "WEAPON_" + str(i))
		debug_container.add_child(marker)
	
	# Cover positions (Yellow spheres - limited to 15 for clarity)
	for i in range(min(cover_positions.size(), 15)):
		var marker = create_debug_marker(cover_positions[i], Color.YELLOW, "COVER_" + str(i))
		debug_container.add_child(marker)
	
	var scene_root = get_scene_root()
	if scene_root:
		set_owner_recursive(debug_container, scene_root)
	
	print("🎯 Debug System Ready - " + str(spawn_points.size()) + " spawns, " + str(strategic_positions.size()) + " strategic, " + str(weapon_spawn_points.size()) + " weapons, " + str(cover_positions.size()) + " cover")

func create_debug_marker(pos: Vector3, color: Color, label: String) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	marker.name = "Debug_" + label
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 2.0
	sphere_mesh.height = 4.0
	
	marker.mesh = sphere_mesh
	marker.position = pos + Vector3(0, 4, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_unshaded = true
	material.flags_transparent = true
	material.albedo_color.a = 0.8
	marker.material_override = material
	
	return marker

func update_debug_markers():
	var debug_container = get_node_or_null("Debug_Markers")
	if debug_container:
		debug_container.queue_free()
	
	if enable_debug_markers and spawn_points.size() > 0:
		call_deferred("add_debug_markers")

func clear_all_children():
	if not Engine.is_editor_hint():
		return
	
	for child in get_children():
		child.queue_free()
	
	spawn_points.clear()
	strategic_positions.clear()
	weapon_spawn_points.clear()
	cover_positions.clear()
	
	print("🧹 Level cleared!")

func set_all_owners():
	if not Engine.is_editor_hint():
		return
	
	var scene_root = get_scene_root()
	if scene_root:
		set_owner_recursive(self, scene_root)

func get_scene_root() -> Node:
	if get_tree() and get_tree().edited_scene_root:
		return get_tree().edited_scene_root
	else:
		return self

func set_owner_recursive(node: Node, scene_root: Node):
	if node != scene_root:
		node.owner = scene_root
	
	for child in node.get_children():
		set_owner_recursive(child, scene_root)
