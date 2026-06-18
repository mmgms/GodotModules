extends SteeringBehaviour2D
class_name SteeringFollowPath2D

var _path: Array[Vector2]

var _path_offset := 0.0
var _loop: bool

# The distance along the path to generate the next target position.
func set_path_offset(path_offset: float):
	_path_offset = path_offset
	return self

func set_loop(loop: bool):
	_loop = loop
	return self
	
func set_path(path: Array[Vector2]):
	_current_path_idx = 0
	_path = path
	return self


var _current_path_idx: int = 0
func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, accel: TargetAccelleration):
	if _path.is_empty():
		return
		
	var _next_point = _path[_current_path_idx]
	
	var distance_to_next_point = agent.position.distance_to(_next_point)
	if distance_to_next_point < _path_offset:
		if not _loop:
			_current_path_idx = clampi(_current_path_idx + 1, 0, _path.size()-1)
		else:
			_current_path_idx = wrapi(_current_path_idx + 1, 0, _path.size())
		
	accel.linear = (_next_point - agent.position).normalized() * parameters.linear_acceleration_max
	accel.angular = 0.0	
	
