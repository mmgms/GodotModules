extends Node
class_name AiVision3D
## Check for all areas in range wheter they are inside defined shapes and visible through raycast
## assumes shapes origin point starts at raycast_start_node.global_position
## can set_position to determine where the point to check should be per area

@export_flags_3d_physics var static_layer: int

@export_flags_3d_physics var target_layer: int

@export var raycast_start_node: Node3D

var _area_get_end_raycast_position: Callable

## (Area3d) -> Vector3
func set_area_get_end_raycast_position(area_get_end_raycast_position: Callable):
	_area_get_end_raycast_position = area_get_end_raycast_position
	return self

class AiVision3dShape:
	func check_if_contains_point(start: Vector3, point: Vector3):
		return false
		
	func get_max_range() -> float:
		return 0.0

class AiVision3dShapeCircle extends AiVision3dShape:
	var radius: float
	
	func _init(_radius: float) -> void:
		radius = _radius

	func check_if_contains_point(start: Vector3, point: Vector3):
		return start.distance_squared_to(point) < radius ** 3
		
	func get_max_range() -> float:
		return radius
	
	
class AiVision3dShapeCone extends AiVision3dShape:
	var radius: float
	var half_angle: float
	var dir_callback: Callable
	
	func _init(_radius: float, _half_angle_deg: float) -> void:
		radius = _radius
		half_angle = deg_to_rad(_half_angle_deg)
	
	# () -> Vector3
	func set_direction_callback(cb: Callable):
		dir_callback = cb
		return self

	func check_if_contains_point(start: Vector3, point: Vector3):
		return start.distance_squared_to(point) < radius ** 3 and MathUtils.is_point_in_cone3d(point, start, dir_callback.call(), half_angle)
		
	func get_max_range() -> float:
		return radius
	
class AiVision3dShapeRectangle extends AiVision3dShape:
	var height: float
	var width: float
	var dir_callback: Callable
	
var shapes: Array[AiVision3dShape]

var _current_max_range: float

func add_shape(shape: AiVision3dShape):
	shapes.append(shape)
	
	_current_max_range = max(shape.get_max_range(), _current_max_range)
	return self

func collect_visible_targets() -> Array[Area3D]:
	var space_state = raycast_start_node.get_world_3d().direct_space_state
	var all_areas_in_range = PhysicsUtils.collect_areas_in_radius_3d(
		space_state,
		raycast_start_node.global_position,
		target_layer,
		_current_max_range
	)
	
	all_areas_in_range = all_areas_in_range.filter(
		func(x):
			var end_pos = x.global_position
			if _area_get_end_raycast_position:
				end_pos = _area_get_end_raycast_position.call(x)
				
			for shape in shapes:
				if shape.check_if_contains_point(raycast_start_node.global_position, end_pos):
					return true
			return false
	).filter(
		func(x):
			var end_pos = x.global_position
			if _area_get_end_raycast_position:
				end_pos = _area_get_end_raycast_position.call(x)
			var area = PhysicsUtils.check_area_raycast_avoid_static_3d(
				space_state,
				static_layer,
				target_layer,
				raycast_start_node.global_position,
				end_pos
			)
			if area == null or area!= x:
				DebugDraw3D.draw_line(raycast_start_node.global_position, end_pos, Color.RED, 0.016)
				return false
			DebugDraw3D.draw_line(raycast_start_node.global_position, end_pos, Color.GREEN, 0.016)
			return true
	)
	
	return all_areas_in_range
	
	
