# Calculates acceleration to take an agent directly away from a target agent.
class_name SteeringFlee3D
extends SteeringBehaviour3D


var _get_target_position_callback: Callable

## signature () -> Vector3
func set_target_position_callback(callback: Callable):
	_get_target_position_callback = callback
	return self

func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration) -> void:
	if not _get_target_position_callback:
		return

	var target_position = _get_target_position_callback.call()
	accel.linear = (
		(agent.position - target_position).normalized()
		* parameters.linear_acceleration_max
	)
	accel.angular = 0
