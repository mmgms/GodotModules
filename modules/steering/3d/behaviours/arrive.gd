
extends SteeringBehaviour3D
class_name SteeringArrive3D

# Distance from the target for the agent to be considered successfully
# arrived.
var arrival_tolerance: float = 0.00
# Distance from the target for the agent to begin slowing down.
var deceleration_radius: float = 1.0
# Represents the time it takes to change acceleration.
var time_to_reach := 0.1


var _get_target_position_callback: Callable

## signature () -> Vector3
func set_target_position_callback(callback: Callable):
	_get_target_position_callback = callback
	return self

func set_arrival_tolerance(val: float):
	arrival_tolerance = val
	return self

func set_deceleration_radius(val: float):
	deceleration_radius = val
	return self

func set_time_to_reach(val: float):
	time_to_reach = val
	return self

func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration):
	if not _get_target_position_callback:
		return

	var to_target = _get_target_position_callback.call() - agent.position
	var distance = to_target.length()

	if distance <= arrival_tolerance:
		accel.set_zero()
	else:
		var desired_speed = parameters.linear_speed_max

		if distance <= deceleration_radius:
			desired_speed *= distance / deceleration_radius

		var desired_velocity = to_target * desired_speed / distance

		desired_velocity = ((desired_velocity - agent.linear_velocity) * 1.0 / time_to_reach)

		accel.linear = MathUtils.clampedv3(desired_velocity, parameters.linear_acceleration_max)
		accel.angular = 0
