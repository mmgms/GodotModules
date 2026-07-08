# Calculates acceleration to take an agent away from where a target agent is
# moving.
class_name SteeringEvade3D
extends SteeringBehaviour3D


var _get_target_callback: Callable

# () -> SteeringAgent3D
func set_get_target_callback(cb: Callable):
	_get_target_callback = cb
	return self

var predict_time_max: float = 1.0

func set_predict_time_max(time: float):
	predict_time_max = time
	return self


func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration) -> void:

	var target = _get_target_callback.call()
	var target_position = target.position
	var distance_squared = (target_position - agent.position).length_squared()

	var speed_squared := agent.linear_velocity.length_squared()
	var predict_time := predict_time_max

	if speed_squared > 0:
		var predict_time_squared = distance_squared / speed_squared
		if predict_time_squared < predict_time_max * predict_time_max:
			predict_time = sqrt(predict_time_squared)

	accel.linear = ((target_position + (target.linear_velocity * predict_time)) - agent.position).normalized()
	accel.linear *= -parameters.linear_acceleration_max

	accel.angular = 0
