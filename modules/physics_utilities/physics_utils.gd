class_name PhysicsUtils


static func collect_areas_in_radius_2d(space_state: PhysicsDirectSpaceState2D, 
		position: Vector2,
		area_layer: int, 
		radius: float) -> Array[Area2D]:

	var query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	query.collision_mask = area_layer

	query.shape = CircleShape2D.new()
	query.shape.radius = radius
	query.transform = Transform2D(0, position)

	var res = space_state.intersect_shape(query)
	if res.is_empty():
		return []
		
	return res.map(func(x): return x.collider as Area2D)

static func check_area_raycast_avoid_static_2d(space_state: PhysicsDirectSpaceState2D, 
		static_layer: int, 
		area_layer: int, 
		from: Vector2, 
		to: Vector2) -> Area2D:

	var query = PhysicsRayQueryParameters2D.create(from, to) 
	query.collide_with_areas = true
	query.collide_with_bodies = true

	query.collision_mask = static_layer | area_layer

	var res = space_state.intersect_ray(query)
	if res.is_empty() or res.collider is StaticBody2D:
		return null

	
	return res.collider as Area2D