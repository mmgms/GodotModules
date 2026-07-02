extends SteeringBehaviour3D
class_name SteeringSeek3D

var _get_target_position_callback: Callable

## signature () -> Vector3
func set_target_position_callback(callback: Callable):
	_get_target_position_callback = callback
	return self
	

func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration):
	if not _get_target_position_callback:
		return
	
	var to_target = _get_target_position_callback.call() - agent.position
	var to_target_flat = Vector3(to_target.x, 0.0, to_target.z)
	accel.linear = to_target_flat.normalized() * parameters.linear_acceleration_max
	accel.angular = 0.0
