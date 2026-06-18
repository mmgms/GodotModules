extends SteeringBehaviour2D
class_name SteeringBlend

var _behaviors := []
var _accel = SteeringBehaviour2D.TargetAccelleration.new()


# Appends a behavior to the internal array along with its `weight`.
func add(behavior: SteeringBehaviour2D, weight: float):
	_behaviors.append({behavior = behavior, weight = weight})
	return self


func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, blended_accel: TargetAccelleration) -> void:
	blended_accel.set_zero()

	for i in range(_behaviors.size()):
		var bw: Dictionary = _behaviors[i]
		if is_zero_approx(bw.weight):
			continue
		bw.behavior.calculate_steering(agent, parameters, _accel)

		blended_accel.add_scaled_accel(_accel, bw.weight)

	blended_accel.linear = blended_accel.linear.limit_length(parameters.linear_acceleration_max)
	blended_accel.angular = clamp(blended_accel.angular, 
		-parameters.angular_acceleration_max, 
		parameters.angular_acceleration_max
		)
