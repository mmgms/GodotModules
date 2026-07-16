# Calculates an acceleration that repels the agent from its neighbors 
# The acceleration is an average based on all neighbors, multiplied by a
# strength decreasing by the inverse square law in relation to distance, and it
# accumulates.
class_name SteeringSeparation3D
extends SteeringBehaviour3D

# The coefficient to calculate how fast the separation strength decays with distance.
var decay_coefficient := 1.0

func set_decay_coefficient(val: float):
	decay_coefficient = val
	return self

var _acceleration: TargetAccelleration

var _proximity_callback: Callable

# () -> Array[SteeringAgent3D]
func set_proximity_callback(cb: Callable):
	_proximity_callback = cb
	return self


func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration) -> void:
	accel.set_zero()
	self._acceleration = accel
	# warning-ignore:return_value_discarded
	var neighbors = _proximity_callback.call()
	for neigh in neighbors:
		_report_neighbor(parameters, agent, neigh)



# Callback for the proximity to call when finding neighbors. Determines the amount of
# acceleration that `neighbor` imposes based on its distance from the owner agent.
func _report_neighbor(parameters: SteeringParameters3D, agent: SteeringAgent3D, neighbor: SteeringAgent3D) -> bool:
	var to_agent := agent.position - neighbor.position

	var distance_squared := to_agent.length_squared() + 0.1
	var acceleration_max := parameters.linear_acceleration_max

	var strength := decay_coefficient / distance_squared
	if strength > acceleration_max:
		strength = acceleration_max

	_acceleration.linear += to_agent * (strength / sqrt(distance_squared))

	return true
