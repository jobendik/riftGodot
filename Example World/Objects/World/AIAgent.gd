extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@export var speed = 3.0
@export var acceleration = 10.0

var target_position: Vector3
var random_walk_timer = 0.0
var random_walk_interval = 8.0  # Økt til 8 sekunder
var exploration_radius = 30.0  # Hvor langt agenten vil utforske
var visited_areas: Array[Vector3] = []  # Husker hvor den har vært
var current_exploration_target: Vector3
var exploration_mode = true
var idle_timer = 0.0

func _ready():
	# Vent til navigation er klar
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Sett agent-egenskaper
	nav_agent.path_desired_distance = 2.0  # Økt så den ikke stopper for tidlig
	nav_agent.target_desired_distance = 3.0  # Økt så den ikke bytter mål for ofte
	nav_agent.radius = 0.5
	nav_agent.height = 2.0
	nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	
	print("=== Explorer Agent Started ===")
	print("Starting exploration from: ", global_position)
	
	# Start med et utforskingsmål
	set_exploration_target()

func _physics_process(delta):
	# Oppdater timers
	random_walk_timer += delta
	idle_timer += delta
	
	# Sjekk om vi har nådd målet eller trenger nytt mål
	if nav_agent.is_navigation_finished() or nav_agent.distance_to_target() < 4.0:
		idle_timer += delta
		
		# Hvis vi har vært stille lenge nok, finn nytt mål
		if idle_timer > 2.0:
			mark_area_as_visited(global_position)
			set_exploration_target()
			idle_timer = 0.0
	
	# Periodisk ny utforsking (hver 8-12 sekund)
	if random_walk_timer >= random_walk_interval:
		mark_area_as_visited(global_position)
		set_exploration_target()
		random_walk_timer = 0.0
		# Varierend interval for mer naturlig oppførsel
		random_walk_interval = randf_range(8.0, 12.0)
	
	# Gravitasjon
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	
	# Bevegelse
	if nav_agent.is_navigation_finished():
		# Slow down when reaching target
		velocity.x = move_toward(velocity.x, 0, acceleration * delta * 2)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta * 2)
	else:
		move_towards_target(delta)
	
	move_and_slide()

func move_towards_target(delta):
	var current_pos = global_position
	var next_path_pos = nav_agent.get_next_path_position()
	
	# Beregn horisontal avstand
	var horizontal_distance = Vector2(
		next_path_pos.x - current_pos.x,
		next_path_pos.z - current_pos.z
	).length()
	
	# Hvis neste punkt er for nært, ikke beveg
	if horizontal_distance < 1.0:
		return
	
	# Beregn retning
	var direction = Vector3(
		next_path_pos.x - current_pos.x,
		0,
		next_path_pos.z - current_pos.z
	).normalized()
	
	# Beveg karakteren
	var target_velocity = direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

func set_exploration_target():
	var best_target = find_unexplored_area()
	
	if best_target != Vector3.ZERO:
		current_exploration_target = best_target
		nav_agent.target_position = best_target
		print("🗺️ Exploring new area: ", best_target)
	else:
		# Hvis alt er utforsket, gå til et tilfeldig sted langt unna
		set_long_distance_target()

func find_unexplored_area() -> Vector3:
	var attempts = 0
	var max_attempts = 15
	var best_target = Vector3.ZERO
	var best_distance_from_visited = 0.0
	
	while attempts < max_attempts:
		# Generer et mål i en stor radius
		var angle = randf() * TAU  # 0 til 2π
		var distance = randf_range(10.0, exploration_radius)
		
		var potential_target = global_position + Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		
		# Sjekk hvor langt dette er fra alle besøkte områder
		var min_distance_to_visited = INF
		for visited_pos in visited_areas:
			var dist = potential_target.distance_to(visited_pos)
			if dist < min_distance_to_visited:
				min_distance_to_visited = dist
		
		# Hvis dette er langt fra besøkte områder, er det en god kandidat
		if min_distance_to_visited > best_distance_from_visited:
			best_distance_from_visited = min_distance_to_visited
			best_target = potential_target
		
		attempts += 1
	
	# Kun returner hvis det er langt nok fra besøkte områder
	if best_distance_from_visited > 8.0:
		return best_target
	else:
		return Vector3.ZERO

func set_long_distance_target():
	# Gå til et sted langt unna på kartet
	var directions = [
		Vector3(1, 0, 0),    # Øst
		Vector3(-1, 0, 0),   # Vest  
		Vector3(0, 0, 1),    # Nord
		Vector3(0, 0, -1),   # Sør
		Vector3(1, 0, 1),    # Nordøst
		Vector3(-1, 0, 1),   # Nordvest
		Vector3(1, 0, -1),   # Sørøst
		Vector3(-1, 0, -1)   # Sørvest
	]
	
	var chosen_direction = directions[randi() % directions.size()]
	var distance = randf_range(20.0, 40.0)
	
	current_exploration_target = global_position + chosen_direction * distance
	nav_agent.target_position = current_exploration_target
	
	print("🚀 Long distance exploration: ", current_exploration_target)

func mark_area_as_visited(pos: Vector3):
	# Sjekk om dette området allerede er markert som besøkt
	for visited_pos in visited_areas:
		if pos.distance_to(visited_pos) < 5.0:  # Innenfor 5 enheter
			return  # Allerede besøkt
	
	# Legg til som nytt besøkt område
	visited_areas.append(pos)
	print("📍 Marked area as visited: ", pos, " (Total: ", visited_areas.size(), ")")
	
	# Begrens antall huskede områder for performance
	if visited_areas.size() > 20:
		visited_areas.pop_front()

func set_target(pos: Vector3):
	# Funksjon for manuell målsetting
	current_exploration_target = pos
	nav_agent.target_position = pos
	random_walk_timer = 0.0
	idle_timer = 0.0
	print("🎯 Manual target set: ", pos)

func _on_input_event(camera, event, position, normal, shape_idx):
	# Optional: Klikk for å sette nytt mål
	if event is InputEventMouseButton and event.pressed:
		set_target(position)
