extends SteeringBehaviour2D
class_name SteerinSeek2D

var _get_target_position_callback: Callable

## signature () -> Vector2
func set_target_position_callback(callback: Callable):
	_get_target_position_callback = callback
	return self
	

func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, accel: TargetAccelleration):
	if not _get_target_position_callback:
		return
		
	accel.linear = (_get_target_position_callback.call() - agent.position).normalized() * parameters.linear_acceleration_max
	accel.angular = 0.0
