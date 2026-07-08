# Calculates acceleration to take an agent directly away from a target agent.
class_name SteeringFlee2D
extends SteeringBehaviour2D


var _get_target_position_callback: Callable

## signature () -> Vector2
func set_target_position_callback(callback: Callable):
	_get_target_position_callback = callback
	return self

func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, accel: TargetAccelleration) -> void:
	if not _get_target_position_callback:
		return

	var target_position = _get_target_position_callback.call()
	accel.linear = (
		(agent.position - target_position).normalized()
		* parameters.linear_acceleration_max
	)
	accel.angular = 0
