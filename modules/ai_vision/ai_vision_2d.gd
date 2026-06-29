extends Node
class_name AiVision2D
## Check for all areas in range wheter they are visible through raycast

@export_flags_2d_physics var static_layer: int

@export_flags_2d_physics var target_layer: int

@export var raycast_start_node: Node2D

class AiVision2dShape:
	func check_if_contains_point(start: Vector2, point: Vector2):
		return false
		
	func get_max_range() -> float:
		return 0.0

class AiVision2dShapeCircle extends AiVision2dShape:
	var radius: float
	
	func _init(_radius: float) -> void:
		radius = _radius

	func check_if_contains_point(start: Vector2, point: Vector2):
		return start.distance_squared_to(point) < radius ** 2
		
	func get_max_range() -> float:
		return radius
	
	
class AiVision2dShapeCone extends AiVision2dShape:
	var radius: float
	var half_angle: float
	var dir_callback: Callable
	
	func _init(_radius: float, _half_angle_deg: float) -> void:
		radius = _radius
		half_angle = deg_to_rad(_half_angle_deg)
	
	# () -> Vector2
	func set_direction_callback(cb: Callable):
		dir_callback = cb
		return self

	func check_if_contains_point(start: Vector2, point: Vector2):
		return start.distance_squared_to(point) < radius ** 2 and MathUtils.is_point_in_cone2d(point, start, dir_callback.call(), half_angle)
		
	func get_max_range() -> float:
		return radius
	
class AiVision2dShapeRectangle extends AiVision2dShape:
	var height: float
	var width: float
	var dir_callback: Callable
	
var shapes: Array[AiVision2dShape]

var _current_max_range: float

func add_shape(shape: AiVision2dShape):
	shapes.append(shape)
	
	_current_max_range = max(shape.get_max_range(), _current_max_range)
	return self

func collect_visible_targets() -> Array[Area2D]:
	var space_state = raycast_start_node.get_world_2d().direct_space_state
	var all_areas_in_range = PhysicsUtils.collect_areas_in_radius_2d(
		space_state,
		raycast_start_node.global_position,
		target_layer,
		_current_max_range
	)
	
	all_areas_in_range = all_areas_in_range.filter(
		func(x):
			for shape in shapes:
				if shape.check_if_contains_point(raycast_start_node.global_position, x.global_position):
					return true
			return false
	).filter(
		func(x):
			var area = PhysicsUtils.check_area_raycast_avoid_static_2d(
				space_state,
				static_layer,
				target_layer,
				raycast_start_node.global_position,
				x.global_position
			)
			if area == null or area!= x:
				MyDebugDraw2d.line(raycast_start_node.global_position, x.global_position, 0.016, Color.RED)
				return false
			MyDebugDraw2d.line(raycast_start_node.global_position, x.global_position, 0.016, Color.GREEN)
			return true
	)
	
	return all_areas_in_range
	
	
	
