class_name PhysicsUtils


static func collect_areas_in_radius_2d(space_state: PhysicsDirectSpaceState2D, 
		position: Vector2,
		area_layer: int, 
		radius: float) -> Array[Area2D]:
	
	var areas = [] as Array[Area2D]
	var query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	query.collision_mask = area_layer

	query.shape = CircleShape2D.new()
	query.shape.radius = radius
	query.transform = Transform2D(0, position)

	var res = space_state.intersect_shape(query)
	if res.is_empty():
		return areas
	
	areas.assign(res.map(func(x): return x.collider as Area2D))
	return areas

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



static func collect_areas_in_radius_3d(space_state: PhysicsDirectSpaceState3D, 
		position: Vector3,
		area_layer: int, 
		radius: float) -> Array[Area3D]:
	
	var areas = [] as Array[Area3D]
	var query = PhysicsShapeQueryParameters3D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	query.collision_mask = area_layer

	query.shape = SphereShape3D.new()
	query.shape.radius = radius
	query.transform = Transform3D(Basis.IDENTITY, position)

	var res = space_state.intersect_shape(query)
	if res.is_empty():
		return areas
	
	areas.assign(res.map(func(x): return x.collider as Area3D))
	return areas

static func check_area_raycast_avoid_static_3d(space_state: PhysicsDirectSpaceState3D, 
		static_layer: int, 
		area_layer: int, 
		from: Vector3, 
		to: Vector3) -> Area3D:

	var query = PhysicsRayQueryParameters3D.create(from, to) 
	query.collide_with_areas = true
	query.collide_with_bodies = true

	query.collision_mask = static_layer | area_layer

	var res = space_state.intersect_ray(query)
	if res.is_empty() or res.collider is StaticBody3D:
		return null

	
	return res.collider as Area3D


class RaycastCollisionResult3D:
	var position: Vector3
	var normal: Vector3

# returns null if no collision
static func check_static_raycast_collision_3d(space_state: PhysicsDirectSpaceState3D, 
		static_layer: int, 
		from: Vector3, 
		to: Vector3) -> RaycastCollisionResult3D:
	
	var raycast_res = RaycastCollisionResult3D.new()
	var query = PhysicsRayQueryParameters3D.create(from, to) 
	query.collide_with_areas = false
	query.collide_with_bodies = true

	query.collision_mask = static_layer

	var res = space_state.intersect_ray(query)
	if res.is_empty():
		return null

	raycast_res.position = res.position
	raycast_res.normal = res.normal
	
	return raycast_res


class RaycastCollisionResult2D:
	var position: Vector2
	var normal: Vector2

# returns null if no collision
static func check_static_raycast_collision_2d(space_state: PhysicsDirectSpaceState2D, 
		static_layer: int, 
		from: Vector2, 
		to: Vector2) -> RaycastCollisionResult2D:
	
	var raycast_res = RaycastCollisionResult2D.new()
	var query = PhysicsRayQueryParameters2D.create(from, to) 
	query.collide_with_areas = false
	query.collide_with_bodies = true

	query.collision_mask = static_layer

	var res = space_state.intersect_ray(query)
	if res.is_empty():
		return null

	raycast_res.position = res.position
	raycast_res.normal = res.normal
	
	return raycast_res



func collect_bodies_in_radius_2d(space_state: PhysicsDirectSpaceState2D, 
		position: Vector2,
		body_layer: int, 
		radius: float) -> Array[PhysicsBody2D]:
	
	var bodies = [] as Array[PhysicsBody2D]
	var query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = false
	query.collide_with_bodies = true

	query.collision_mask = body_layer

	query.shape = CircleShape2D.new()
	query.shape.radius = radius
	query.transform = Transform2D(0, position)

	var res = space_state.intersect_shape(query)
	if res.is_empty():
		return bodies
	
	bodies.assign(res.map(func(x): return x.collider as PhysicsBody2D))
	return bodies



func collect_bodies_in_radius_3d(space_state: PhysicsDirectSpaceState3D, 
		position: Vector3,
		body_layer: int, 
		radius: float) -> Array[PhysicsBody3D]:
	
	var bodies = [] as Array[PhysicsBody3D]
	var query = PhysicsShapeQueryParameters3D.new()
	query.collide_with_areas = false
	query.collide_with_bodies = true

	query.collision_mask = body_layer

	query.shape = SphereShape3D.new()
	query.shape.radius = radius
	query.transform = Transform3D(Basis.IDENTITY, position)

	var res = space_state.intersect_shape(query)
	if res.is_empty():
		return bodies
	
	bodies.assign(res.map(func(x): return x.collider as PhysicsBody3D))
	return bodies

# creates and attaches as body_a child a damped spring joint from body_a to body_b
func create_damped_spring_joint(body_a: PhysicsBody2D, body_b: PhysicsBody2D, rest_length, stiffness=100, damping=1.0, bias=1.0):
	var joint = DampedSpringJoint2D.new()
	body_a.add_child(joint)
	
	joint.stiffness = stiffness
	joint.rest_length = rest_length
	joint.damping = damping
	joint.bias = bias
	joint.look_at(body_b.global_position)
	joint.rotation -= deg_to_rad(90)
	joint.length = body_a.global_position.distance_to(body_b.global_position)

	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
