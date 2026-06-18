extends SteeringBehaviour2D
class_name SteeringFace2D

var _get_target_position_callback: Callable

# The amount of distance in radians for the behavior to consider itself close
# enough to be matching the target agent's rotation.
var _alignment_tolerance: float = deg_to_rad(1)

# The amount of distance in radians from the goal to start slowing down.
var _deceleration_radius: float = 20

# The amount of time to reach the target velocity
var _time_to_reach: float = 0.1

func set_alignment_tolerance(alignment_tolerance: float):
	_alignment_tolerance = alignment_tolerance
	return self
	
func set_deceleration_radius(deceleration_radius: float):
	_deceleration_radius = deceleration_radius
	return self
	
func set_time_to_reach(time_to_reach: float):
	_time_to_reach = time_to_reach
	return self

## signature () -> Vector2
func set_target_position_callback(callback: Callable):
	_get_target_position_callback = callback
	return self

var last_angle_difference = INF

func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, acceleration: TargetAccelleration):
	if not _get_target_position_callback:
		return

	var to_target = _get_target_position_callback.call() - agent.position
	var distance_squared = (to_target as Vector2).length_squared()

	if distance_squared < parameters.zero_linear_speed_threshold:
		acceleration.set_zero()
	else:
		var orientation = (to_target as Vector2).angle()
		last_angle_difference = _match_orientation(agent, parameters, acceleration, orientation)


func _match_orientation(agent: SteeringAgent2D, parameters: SteeringParameters2D, acceleration: TargetAccelleration, desired_orientation: float):
	var rotation := wrapf(desired_orientation - agent.orientation, -PI, PI)

	var rotation_size := absf(rotation)

	if rotation_size <= _alignment_tolerance:
		acceleration.set_zero()
	else:
		var desired_rotation = parameters.angular_speed_max

		if rotation_size <= _deceleration_radius:
			desired_rotation *= rotation_size / _deceleration_radius

		desired_rotation *= rotation / rotation_size

		acceleration.angular = ((desired_rotation - agent.angular_velocity) / _time_to_reach)

		var limited_acceleration := absf(acceleration.angular)
		if limited_acceleration > parameters.angular_acceleration_max:
			acceleration.angular *= (parameters.angular_acceleration_max / limited_acceleration)

	acceleration.linear = Vector2.ZERO
	return rotation_size
