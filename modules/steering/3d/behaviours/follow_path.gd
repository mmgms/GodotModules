extends SteeringBehaviour3D
class_name SteeringFollowPath3D
# need to set path offset

var _path: Array[Vector3]

var _path_offset := 1.0
var _loop: bool

# The distance along the path to generate the next target position.
func set_path_offset(path_offset: float):
	_path_offset = path_offset
	return self

func set_loop(loop: bool):
	_loop = loop
	return self
	
func set_path(path: Array[Vector3]):
	_current_path_idx = 0
	_path = path
	return self


var _current_path_idx: int = 0
func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration):
	if _path.is_empty():
		return
		
	var _next_point = _path[_current_path_idx]

	DebugDraw3D.draw_sphere(_next_point, 0.2, Color.GREEN, 0.016)
	
	var distance_to_next_point = agent.position.distance_to(_next_point)
	if distance_to_next_point < _path_offset:
		if not _loop:
			_current_path_idx = clampi(_current_path_idx + 1, 0, _path.size()-1)
		else:
			_current_path_idx = wrapi(_current_path_idx + 1, 0, _path.size())
	
	var to_target = _next_point - agent.position
	var to_target_flat = Vector3(to_target.x, 0.0, to_target.z)
	
	accel.linear = to_target_flat.normalized() * parameters.linear_acceleration_max
	accel.angular = 0.0	
