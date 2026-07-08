# Container for multiple behaviors that returns the result of the first child
# behavior with non-zero acceleration.
class_name SteeringPriority3D
extends SteeringBehaviour3D

var _behaviors := []

# The index of the last behavior the container prioritized.
var last_selected_index: int

# If a behavior's acceleration is lower than this threshold, the container
# considers it has an acceleration of zero.
var zero_threshold: float = 0.001
func set_zero_threshold(val: float):
	zero_threshold = val
	return self

func add(behavior: SteeringBehaviour3D):
	_behaviors.append(behavior)
	return self


# Returns the behavior at the position in the pool referred to by `index`, or
# `null` if no behavior was found.
func get_behavior_at(index: int):
	if _behaviors.size() > index:
		return _behaviors[index]
	printerr("Tried to get index " + str(index) + " in array of size " + str(_behaviors.size()))
	return null


func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration) -> void:
	var threshold_squared := zero_threshold * zero_threshold

	last_selected_index = -1

	var size := _behaviors.size()

	if size > 0:
		for i in range(size):
			last_selected_index = i
			var behavior = _behaviors[i]
			behavior.calculate_steering(accel)

			if accel.get_magnitude_squared() > threshold_squared:
				break
	else:
		accel.set_zero()
